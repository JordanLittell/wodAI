//
//  CountdownFeedback.swift
//  wodAI
//
//  Haptic + audio cues for the pre-workout "get ready" countdown. A light tick
//  each second and a stronger "go" cue at zero, audible even with the ringer
//  silent (the audio session ducks the athlete's music instead of stopping it).
//
//  Uses only system sounds so no bundled audio asset is required. Future
//  upgrade: bundle short `beep.wav`/`go.wav` files and play them with an
//  AVAudioPlayer for a custom tone.
//

import Foundation
import UIKit
import AudioToolbox
import AVFoundation

final class CountdownFeedback {
    private let tickHaptic = UIImpactFeedbackGenerator(style: .light)
    private let goHaptic = UINotificationFeedbackGenerator()

    // Short system sounds: "Tock" for the per-second tick, "begin recording"
    // tone for the go cue.
    private let tickSoundID: SystemSoundID = 1105
    private let goSoundID: SystemSoundID = 1113

    /// Prime the haptic engines and configure the audio session so cues are
    /// audible on silent while ducking (not stopping) any background audio.
    func prepare() {
        tickHaptic.prepare()
        goHaptic.prepare()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "CountdownFeedback.prepare"])
        }
    }

    func playTick() {
        tickHaptic.impactOccurred()
        tickHaptic.prepare()
        AudioServicesPlaySystemSound(tickSoundID)
    }

    /// Plays the "go" cue and leaves the audio session **active**: the workout is
    /// starting and `WorkoutCueScheduler` takes the session over from here for
    /// in-workout interval cues. Tearing it down here would drop the audio route
    /// and silence the rest of the workout.
    func playGo() {
        goHaptic.notificationOccurred(.success)
        AudioServicesPlaySystemSound(goSoundID)
    }

    /// Release the audio session (unduck background audio) when the countdown
    /// ends or is cancelled.
    func reset() {
        deactivateSession()
    }

    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "CountdownFeedback.deactivate"])
        }
    }
}
