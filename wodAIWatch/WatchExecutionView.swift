//
//  WatchExecutionView.swift
//  wodAI Watch
//
//  The on-watch workout experience: a 3-page swipeable TabView (Time / Workout
//  text / Heart rate + sensors), plus idle, pre-roll countdown, and finished states.
//

import SwiftUI

struct WatchExecutionView: View {
    @ObservedObject var coordinator: WatchSessionCoordinator
    @ObservedObject var engine: ExecutionEngine
    @ObservedObject var workout: WatchWorkoutSession
    @ObservedObject var motion: MotionCollector

    var body: some View {
        switch engine.state {
        case .idle:
            WaitingView()
        case .countdown:
            CountdownView(remaining: engine.countdownRemaining)
        case .running, .paused:
            ExecutionPager(coordinator: coordinator, engine: engine, workout: workout, motion: motion)
        case .finished(let elapsed):
            FinishedView(elapsed: elapsed, rounds: engine.completedRounds)
        }
    }
}

// MARK: - States

private struct WaitingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Start on your phone")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Find a workout in wodAI and tap Start.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

private struct CountdownView: View {
    let remaining: TimeInterval
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("\(Int(ceil(remaining)))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.green)
                .contentTransition(.numericText())
        }
    }
}

private struct FinishedView: View {
    let elapsed: TimeInterval
    let rounds: Int
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Done").font(.headline)
            Text(TimeFormat.clock(elapsed))
                .font(.title3.monospacedDigit())
            if rounds > 0 {
                Text("\(rounds) rounds").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - The 3-page pager

private struct ExecutionPager: View {
    @ObservedObject var coordinator: WatchSessionCoordinator
    @ObservedObject var engine: ExecutionEngine
    @ObservedObject var workout: WatchWorkoutSession
    @ObservedObject var motion: MotionCollector

    var body: some View {
        TabView {
            TimerScreen(coordinator: coordinator, engine: engine)
                .tag(0)
            WorkoutTextScreen(text: engine.payload.displayText)
                .tag(1)
            HeartRateScreen(workout: workout, motion: motion, elapsed: engine.elapsed)
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Screen 1: Time (format-specific)

private struct TimerScreen: View {
    @ObservedObject var coordinator: WatchSessionCoordinator
    @ObservedObject var engine: ExecutionEngine

    var body: some View {
        VStack(spacing: 4) {
            header
            Text(TimeFormat.clock(engine.displaySeconds))
                .font(.system(size: 52, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(engine.isFinished ? .secondary : .primary)
            subtext
            controls
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder private var header: some View {
        switch engine.payload.format {
        case .emom:
            let idx = engine.timing.emomMinuteIndex(at: engine.elapsed)
            Text("EMOM • Min \(idx + 1)/\(engine.payload.constraintMagnitude)")
                .font(.caption2).foregroundStyle(.secondary)
        case .tabata:
            let phase = engine.timing.tabataPhase(at: engine.elapsed)
            let round = engine.timing.tabataRound(at: engine.elapsed)
            Text("\(phase == .work ? "WORK" : "REST") • Rd \(round)")
                .font(.caption.bold())
                .foregroundStyle(phase == .work ? .green : .orange)
        case .amrap:
            Text("AMRAP \(engine.payload.constraintMagnitude)′")
                .font(.caption2).foregroundStyle(.secondary)
        case .forTime:
            Text("For Time").font(.caption2).foregroundStyle(.secondary)
        case .other:
            EmptyView()
        }
    }

    @ViewBuilder private var subtext: some View {
        switch engine.payload.format {
        case .emom:
            if let movement = engine.timing.emomCurrentMovement(at: engine.elapsed) {
                Text(movement).font(.headline).multilineTextAlignment(.center)
            }
        case .amrap, .forTime:
            Text("\(engine.completedRounds) rounds")
                .font(.caption).foregroundStyle(.secondary)
        case .tabata, .other:
            EmptyView()
        }
    }

    @ViewBuilder private var controls: some View {
        HStack(spacing: 10) {
            if engine.payload.format == .amrap || engine.payload.format == .forTime {
                Button {
                    engine.completeRound()
                    WKHaptics.click()
                } label: { Image(systemName: "plus") }
                    .tint(.green)
            }
            // Pause/resume + stop sync to the phone via the coordinator.
            if engine.isRunning {
                Button {
                    coordinator.pause()
                    WKHaptics.click()
                } label: { Image(systemName: "pause.fill") }
            } else {
                Button {
                    coordinator.resume()
                    WKHaptics.click()
                } label: { Image(systemName: "play.fill") }
                    .tint(.green)
            }
            Button(role: .destructive) {
                coordinator.finish()
                WKHaptics.stop()
            } label: { Image(systemName: "stop.fill") }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - Screen 2: Workout text

private struct WorkoutTextScreen: View {
    let text: String
    var body: some View {
        ScrollView {
            Text(text)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
        }
    }
}

// MARK: - Screen 3: Heart rate + sensors

private struct HeartRateScreen: View {
    @ObservedObject var workout: WatchWorkoutSession
    @ObservedObject var motion: MotionCollector
    let elapsed: TimeInterval

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").foregroundStyle(.red)
                Text(workout.heartRate > 0 ? "\(Int(workout.heartRate))" : "––")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("BPM").font(.caption2).foregroundStyle(.secondary)
            }
            Divider()
            metric("Accel", String(format: "%.2fg", motion.accelerationMagnitude))
            metric("Altitude", String(format: "%+.1fm", motion.relativeAltitude))
            metric("Elapsed", TimeFormat.clock(elapsed))
        }
        .padding(.horizontal, 10)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.monospacedDigit())
        }
    }
}

// MARK: - Helpers

enum TimeFormat {
    /// mm:ss for sub-hour durations, h:mm:ss beyond.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
