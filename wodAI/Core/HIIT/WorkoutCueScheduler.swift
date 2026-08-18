//
//  WorkoutCueScheduler.swift
//  wodAI
//
//  Audible interval cues for the duration of a running workout: a countdown
//  tick at T-3/-2/-1 before each phase change, a transition tone on the change
//  itself, and a distinct finish tone at the time cap.
//
//  Every boundary in a WOD is known up front (`WodTimerConfig.timeline`), so the
//  entire cue track is scheduled into the audio engine the moment the workout
//  starts. Nothing needs to wake up and fire a cue on time — the audio render
//  thread plays them out. Combined with the `audio` background mode this means
//  cues keep sounding with the screen off, the phone locked, or in a pocket,
//  which is the whole point: the athlete should not have to look at the phone.
//
//  The session uses `.mixWithOthers` so cues layer over the athlete's music
//  rather than interrupting or ducking it for the length of the workout.
//

import Foundation
import AVFoundation

final class WorkoutCueScheduler {

    // MARK: - Tuning

    private enum Tone {
        /// T-3/-2/-1 lead-in before a phase change.
        static let tick = (frequency: 880.0, duration: 0.08, amplitude: Float(0.5))
        /// The phase change itself.
        static let transition = (frequency: 1320.0, duration: 0.20, amplitude: Float(0.85))
        /// End of the workout.
        static let finish = (frequency: 1660.0, duration: 0.70, amplitude: Float(0.9))
    }

    private static let sampleRate = 44_100.0

    // MARK: - Audio graph

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

    private lazy var tickBuffer = makeTone(Tone.tick)
    private lazy var transitionBuffer = makeTone(Tone.transition)
    private lazy var finishBuffer = makeTone(Tone.finish)

    /// Retained so a resumed workout can be rescheduled from a new offset.
    private var currentConfig: WodTimerConfig?
    private var isRunning = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    /// Begin (or re-begin) the cue track for `config`, treating `elapsed` as the
    /// amount of the workout already completed. Resume passes the paused elapsed
    /// so the remaining cues line up with the re-anchored clock.
    func start(config: WodTimerConfig, fromElapsed elapsed: TimeInterval = 0) {
        teardownEngine()
        currentConfig = config

        let cues = cueTimes(for: config)
            .map { (time: $0.time - elapsed, kind: $0.kind) }
            .filter { $0.time > 0 }

        // An uncapped "For Time" has no boundaries and so no cues. Release the
        // session `CountdownFeedback` left active, or the athlete's music stays
        // ducked for the whole workout.
        guard !cues.isEmpty else {
            deactivateSession()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)

            if engine.attachedNodes.contains(player) == false {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
            }
            engine.prepare()
            try engine.start()

            // Scheduled before `play()`, so sample times are relative to the
            // start of playback.
            for cue in cues {
                guard let buffer = buffer(for: cue.kind) else { continue }
                let at = AVAudioTime(sampleTime: Int64(cue.time * Self.sampleRate),
                                     atRate: Self.sampleRate)
                player.scheduleBuffer(buffer, at: at, options: [], completionHandler: nil)
            }
            player.play()
            isRunning = true
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "WorkoutCueScheduler.start"])
            stop()
        }
    }

    /// Halt cues and release the audio route. Safe to call when not running —
    /// the session is always released, because `CountdownFeedback` may have
    /// activated it even when this scheduler never did.
    func stop() {
        teardownEngine()
        currentConfig = nil
        deactivateSession()
    }

    private func teardownEngine() {
        guard isRunning || engine.isRunning else { return }
        player.stop()
        engine.stop()
        isRunning = false
    }

    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance()
                .setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "WorkoutCueScheduler.stop"])
        }
    }

    // MARK: - Cue plan

    private enum CueKind { case tick, transition, finish }

    /// Flattens the config's phase boundaries into an ordered cue list. Offset 0
    /// gets no transition tone — `CountdownFeedback.playGo()` already marks the
    /// start of the workout.
    private func cueTimes(for config: WodTimerConfig) -> [(time: TimeInterval, kind: CueKind)] {
        var cues: [(time: TimeInterval, kind: CueKind)] = []

        for boundary in config.timeline where boundary.offset > 0 {
            cues.append((boundary.offset, .transition))
            for lead in 1...3 {
                let tickTime = boundary.offset - TimeInterval(lead)
                if tickTime > 0 { cues.append((tickTime, .tick)) }
            }
        }

        if let total = config.totalDuration, total > 0 {
            // Drop any transition that coincides with the end so the finish tone
            // is the only thing heard there.
            cues.removeAll { abs($0.time - total) < 0.01 && $0.kind == .transition }
            cues.append((total, .finish))
            for lead in 1...3 {
                let tickTime = total - TimeInterval(lead)
                if tickTime > 0 { cues.append((tickTime, .tick)) }
            }
        }

        return cues.sorted { $0.time < $1.time }
    }

    private func buffer(for kind: CueKind) -> AVAudioPCMBuffer? {
        switch kind {
        case .tick: return tickBuffer
        case .transition: return transitionBuffer
        case .finish: return finishBuffer
        }
    }

    // MARK: - Tone synthesis

    /// Builds a short sine tone with a linear attack/release so it does not click
    /// at the buffer edges. Tones are generated rather than bundled so no audio
    /// assets are needed, matching `CountdownFeedback`'s system-sound approach.
    private func makeTone(_ spec: (frequency: Double, duration: Double, amplitude: Float)) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(spec.duration * Self.sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = frameCount
        let total = Double(frameCount)
        // 8ms ramps, or a quarter of the tone if it is shorter than 32ms.
        let ramp = min(0.008 * Self.sampleRate, total / 4)

        for frame in 0..<Int(frameCount) {
            let position = Double(frame)
            let sample = sin(2.0 * .pi * spec.frequency * position / Self.sampleRate)
            var envelope = 1.0
            if position < ramp {
                envelope = position / ramp
            } else if position > total - ramp {
                envelope = (total - position) / ramp
            }
            channel[frame] = Float(sample * envelope) * spec.amplitude
        }
        return buffer
    }

    // MARK: - Interruptions

    /// A phone call or Siri tears down the session and drops every scheduled
    /// cue. On resume, rebuild the remaining track from the current elapsed time
    /// rather than leaving the rest of the workout silent.
    @objc private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }

        switch type {
        case .began:
            player.stop()
            isRunning = false
        case .ended:
            guard let config = currentConfig else { return }
            onInterruptionEnded?(config)
        @unknown default:
            break
        }
    }

    /// Set by the view model: given the config, restart cues from the live
    /// elapsed time. The scheduler has no clock of its own.
    var onInterruptionEnded: ((WodTimerConfig) -> Void)?
}
