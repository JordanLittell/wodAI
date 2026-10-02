//
//  HIITWorkoutCompletionView.swift
//  wodAI
//
//  Post-finish celebration + result-capture screen. Shown once a workout is
//  finished: confetti, a high-level overview of what was just done, an adaptive
//  result editor (chosen by a format classifier), and an RPE 1–10 selector.
//  Purely presentational — driven by a plain `WorkoutCompletionDraft`; the view
//  model wiring (persist + advance) is layered on in Phase B.
//

import SwiftUI
import UIKit

// MARK: - Draft model

/// Which result editor to show. Derived from the workout's free-text `format`
/// and its (`time` | `rounds`) `constraintType`.
enum CompletionKind {
    case forTime        // editable finish time
    case amrap          // rounds + partial reps
    case completionOnly // no numeric result (EMOM / Tabata / DURATION / unknown)
}

/// Mutable draft of a finished workout's recorded result. Seeded at finish time
/// with the captured elapsed seconds; the user edits it on the completion screen
/// before it is persisted.
struct WorkoutCompletionDraft: Identifiable {
    let id: Int                 // workout id (also drives `.fullScreenCover(item:)`)
    let workout: HIITWorkoutItem
    let capturedElapsed: TimeInterval

    var durationSeconds: Int?   // For Time (seeded from capturedElapsed)
    var roundsCompleted: Int?   // AMRAP
    var repsCompleted: Int?     // AMRAP
    var perceivedEffort: Int?   // RPE 1–10
    var notes: String = ""      // private note; sent as nil when blank

    /// Classifier resolution order (see the plan's format→editor matrix):
    /// 1. `format` contains "amrap"                       → .amrap
    /// 2. `format` contains "emom" or "tabata"            → .completionOnly
    /// 3. `format` contains "for time"/"rft" OR
    ///    `constraintType == "time"`                      → .forTime
    /// 4. `constraintType == "rounds"`                    → .amrap
    /// 5. else (DURATION / unknown)                       → .completionOnly
    var kind: CompletionKind {
        let format = (workout.format ?? "").lowercased()
        let constraint = workout.constraintType.lowercased()

        if format.contains("amrap") { return .amrap }
        if format.contains("emom") || format.contains("tabata") { return .completionOnly }
        if format.contains("for time") || format.contains("rft") || constraint == "time" {
            return .forTime
        }
        if constraint == "rounds" { return .amrap }
        return .completionOnly
    }

    /// True when this For-Time workout carries a hard time cap.
    var isCapped: Bool { workout.timeCap != nil }
}

// MARK: - Completion screen

struct HIITWorkoutCompletionView: View {
    @State private var draft: WorkoutCompletionDraft
    /// For-Time only: user hit the cap without finishing all the work.
    @State private var didNotFinish = false
    @FocusState private var notesFocused: Bool
    /// Celebration fires once, on first presentation only.
    @State private var showConfetti = true

    private let onDone: (WorkoutCompletionDraft) -> Void
    /// Takes the live draft, not a bare callback: the edits the user made on
    /// this screen (RPE, notes) live in the view's own @State, so a no-argument
    /// skip would silently submit the un-edited seed draft instead.
    private let onSkip: (WorkoutCompletionDraft) -> Void
    /// The run's heart rate; arrives after the screen is up, so it's passed in
    /// live rather than held in `draft`.
    private let heartRate: CompletionHeartRate
    /// Non-nil when the last submit failed; shown above the bottom bar.
    private let errorMessage: String?
    /// True while a submit is in flight — disables Done/Skip.
    private let isSubmitting: Bool
    /// Abandons the result. Only offered once a submit has failed.
    private let onDiscard: (() -> Void)?

    init(draft: WorkoutCompletionDraft,
         heartRate: CompletionHeartRate = .none,
         errorMessage: String? = nil,
         isSubmitting: Bool = false,
         onDone: @escaping (WorkoutCompletionDraft) -> Void,
         onSkip: @escaping (WorkoutCompletionDraft) -> Void,
         onDiscard: (() -> Void)? = nil) {
        // Seed editable fields so the editors render with sensible defaults.
        var seeded = draft
        switch seeded.kind {
        case .forTime:
            if seeded.durationSeconds == nil {
                seeded.durationSeconds = max(0, Int(seeded.capturedElapsed.rounded()))
            }
        case .amrap:
            if seeded.roundsCompleted == nil { seeded.roundsCompleted = 0 }
            if seeded.repsCompleted == nil { seeded.repsCompleted = 0 }
        case .completionOnly:
            break
        }
        // The effort slider always shows a value, so seed the draft to match its
        // resting position — otherwise a user who never drags it would submit
        // nothing while the screen reads "1".
        if seeded.perceivedEffort == nil { seeded.perceivedEffort = Self.minEffort }
        self._draft = State(initialValue: seeded)
        self.heartRate = heartRate
        self.errorMessage = errorMessage
        self.isSubmitting = isSubmitting
        self.onDone = onDone
        self.onSkip = onSkip
        self.onDiscard = onDiscard
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    overviewCard
                    HeartRateSummaryCard(state: heartRate)
                        .animation(.easeInOut(duration: 0.3), value: heartRate)
                    resultEditor
                    effortSelector
                    notesEditor
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .padding(.bottom, 140)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack {
                Spacer()
                // The bottom bar floats over the scroll view, so while the notes
                // keyboard is up it would sit on top of the field. Hide it and
                // let the keyboard's own Done button return the user to it.
                if !notesFocused { bottomBar }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
            }
        }
        .overlay {
            // One-shot: removed once the burst finishes, so nothing is left in
            // the view tree to be re-run by later state changes.
            if showConfetti {
                ConfettiView { showConfetti = false }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(Color("Success"))
            Text("Workout Complete!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("PrimaryText"))
            Text("Nice work — log how it went.")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Overview (mirrors CompletedHiitCard)

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let format = draft.workout.format, !format.isEmpty {
                        Text(format)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("BrandPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color("BrandPrimary").opacity(0.12))
                            .cornerRadius(6)
                    }
                    Text(draft.workout.stimulus)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                Spacer()
                // No constraint label here: it rendered the raw stored values
                // (`900 time`), which is internal representation, not something
                // an athlete recognises. The format pill on the left already
                // says "For Time" / "AMRAP 20", which is the meaningful framing.
            }

            Text(draft.workout.displayText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)

            if !draft.workout.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(draft.workout.tags) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.purple.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.purple.opacity(0.08))
                            .cornerRadius(6)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }

    // MARK: - Adaptive result editor

    @ViewBuilder
    private var resultEditor: some View {
        switch draft.kind {
        case .forTime:      forTimeEditor
        case .amrap:        amrapEditor
        case .completionOnly: EmptyView()
        }
    }

    // For Time → editable finish time + cap handling.
    private var forTimeEditor: some View {
        sectionCard(title: "Your Time") {
            VStack(spacing: 16) {
                Text(clockString(TimeInterval(draft.durationSeconds ?? 0),
                                 showHours: (draft.durationSeconds ?? 0) >= 3600))
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(didNotFinish ? Color("SecondaryText") : Color("PrimaryText"))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)

                if !didNotFinish {
                    // Fine adjust: the on-screen finish button is slow to reach,
                    // so let the user shave the last few seconds.
                    HStack(spacing: 10) {
                        quickAdjustButton("-10s", delta: -10)
                        quickAdjustButton("-5s", delta: -5)
                        stepButton(systemImage: "minus", delta: -1)
                        stepButton(systemImage: "plus", delta: 1)
                        quickAdjustButton("+5s", delta: 5)
                    }
                }

                if draft.isCapped {
                    Toggle(isOn: $didNotFinish) {
                        Text("Hit the cap — didn't finish")
                            .font(.subheadline)
                            .foregroundColor(Color("PrimaryText"))
                    }
                    .tint(Color("BrandPrimary"))
                    .onChange(of: didNotFinish) { _, hitCap in
                        if hitCap {
                            // Record the full cap as the duration.
                            draft.durationSeconds = draft.workout.timeCap
                        } else {
                            draft.durationSeconds = max(0, Int(draft.capturedElapsed.rounded()))
                        }
                    }
                }
            }
        }
    }

    // AMRAP → rounds completed + partial reps.
    private var amrapEditor: some View {
        sectionCard(title: "Your Score") {
            VStack(spacing: 14) {
                counterRow(
                    label: "Rounds completed",
                    value: Binding(
                        get: { draft.roundsCompleted ?? 0 },
                        set: { draft.roundsCompleted = max(0, $0) }
                    ),
                    minValue: 0
                )
                Divider().background(Color("Border"))
                counterRow(
                    label: "Partial reps",
                    value: Binding(
                        get: { draft.repsCompleted ?? 0 },
                        set: { draft.repsCompleted = max(0, $0) }
                    ),
                    minValue: 0
                )
            }
        }
    }

    // MARK: - Effort (RPE 1–10) — shown for every kind

    /// Plain-language meaning of each RPE value. "7" on its own means nothing to
    /// someone who hasn't been taught the scale, and an unlabelled 1–10 grid is
    /// the main reason the existing selector reads as a rating widget rather
    /// than a question about effort.
    private static func effortDescriptor(_ score: Int) -> String {
        switch score {
        case 1, 2:   return "Very easy — barely worked"
        case 3, 4:   return "Easy — could hold this all day"
        case 5, 6:   return "Moderate — working, still talking"
        case 7, 8:   return "Hard — couldn't hold a conversation"
        case 9:      return "Very hard — nearly everything I had"
        default:     return "Max effort — nothing left"
        }
    }

    /// Warm as the scale climbs, so the row reads as increasing effort at a
    /// glance. Single hue family rather than red/amber/green, which would imply
    /// a good/bad judgement — there is no wrong answer to this question.
    private static func effortTint(_ score: Int) -> Color {
        switch score {
        case 1...4:  return Color("BrandPrimary")
        case 5...7:  return Color("BrandPrimary").opacity(0.85)
        default:     return Color("BrandSecondary")
        }
    }

    private static let minEffort = 1
    private static let maxEffort = 10

    /// The slider works in `Double`; the draft stores whole RPE points. Snapping
    /// happens via the `step:` on the slider, so the only job here is the cast
    /// plus a light tick each time the value actually changes (dragging fires
    /// the setter continuously, including on repeats of the same integer).
    private var effortBinding: Binding<Double> {
        Binding(
            get: { Double(draft.perceivedEffort ?? Self.minEffort) },
            set: { newValue in
                let score = min(Self.maxEffort, max(Self.minEffort, Int(newValue.rounded())))
                guard score != draft.perceivedEffort else { return }
                draft.perceivedEffort = score
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        )
    }

    private var effortSelector: some View {
        let score = draft.perceivedEffort ?? Self.minEffort
        return sectionCard(title: "How hard was it?") {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Self.effortTint(score))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut(duration: 0.2), value: score)

                Slider(
                    value: effortBinding,
                    in: Double(Self.minEffort)...Double(Self.maxEffort),
                    step: 1
                )
                .tint(Self.effortTint(score))
                .accessibilityLabel("Perceived effort")
                .accessibilityValue("\(score) of 10, \(Self.effortDescriptor(score))")

                // Anchors so the ends of the scale are legible at a glance.
                HStack {
                    Text("Easy")
                    Spacer()
                    Text("Max effort")
                }
                .font(.caption2)
                .foregroundColor(Color("SecondaryText"))

                Text(Self.effortDescriptor(score))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut(duration: 0.2), value: score)
            }
        }
    }

    // MARK: - Notes (private, free text)

    /// Mirrors the server's `MAX_NOTES_LENGTH`. Enforced here too so an
    /// over-long note is stopped at the keyboard rather than by a failed
    /// mutation after the user has already tapped Done.
    private static let maxNotesLength = 2000

    private var notesEditor: some View {
        sectionCard(title: "Notes") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Private to you — how did it feel, what did you scale?")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))

                ZStack(alignment: .topLeading) {
                    // TextEditor has no placeholder of its own.
                    if draft.notes.isEmpty {
                        Text("e.g. Scaled pull-ups to bands, legs gone by round 3")
                            .font(.subheadline)
                            .foregroundColor(Color("PlaceholderColor"))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $draft.notes)
                        .font(.subheadline)
                        .foregroundColor(Color("PrimaryText"))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 88)
                        .focused($notesFocused)
                        .onChange(of: draft.notes) { _, new in
                            if new.count > Self.maxNotesLength {
                                draft.notes = String(new.prefix(Self.maxNotesLength))
                            }
                        }
                }
                .padding(6)
                .background(Color("Surface2"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("Border"), lineWidth: 1)
                )

                // Only surfaced as the cap approaches — a counter on an empty
                // field just makes an optional note feel like a form.
                if draft.notes.count > Self.maxNotesLength - 200 {
                    Text("\(Self.maxNotesLength - draft.notes.count) characters left")
                        .font(.caption2)
                        .foregroundColor(Color("SecondaryText"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color("Error"))
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(Color("PrimaryText"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(Color("Error").opacity(0.10))
                .cornerRadius(10)
                .transition(.opacity)
            }

            Button(action: { onDone(draft) }) {
                Group {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(errorMessage == nil ? "Done" : "Try Again")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.7 : 1)

            // After a failure, the secondary action has to be a way out — a
            // second save attempt under a different name would just fail again.
            if errorMessage != nil, let onDiscard {
                Button(action: onDiscard) {
                    Text("Discard and continue")
                        .fontWeight(.medium)
                        .foregroundColor(Color("SecondaryText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .disabled(isSubmitting)
            } else {
                Button(action: { onSkip(draft) }) {
                    Text("Skip")
                        .fontWeight(.medium)
                        .foregroundColor(Color("SecondaryText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .disabled(isSubmitting)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .padding(.horizontal)
        .padding(.bottom, 20)
        .padding(.top, 12)
        .background(
            Color("Surface")
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Reusable pieces

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1)
                .foregroundColor(Color("SecondaryText"))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }

    /// A label with -/+ steppers and a centered value, used for rounds & reps.
    private func counterRow(label: String, value: Binding<Int>, minValue: Int) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color("PrimaryText"))
            Spacer()
            HStack(spacing: 16) {
                circleStepButton(systemImage: "minus") {
                    value.wrappedValue = max(minValue, value.wrappedValue - 1)
                }
                .disabled(value.wrappedValue <= minValue)

                Text("\(value.wrappedValue)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundColor(Color("PrimaryText"))
                    .frame(minWidth: 36)

                circleStepButton(systemImage: "plus") {
                    value.wrappedValue += 1
                }
            }
        }
    }

    private func circleStepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color("BrandPrimary"))
                .frame(width: 36, height: 36)
                .background(Color("BrandPrimary").opacity(0.12))
                .clipShape(Circle())
        }
    }

    // For-Time seconds nudge (±1s).
    private func stepButton(systemImage: String, delta: Int) -> some View {
        Button(action: { adjustDuration(by: delta) }) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("BrandPrimary"))
                .frame(width: 44, height: 44)
                .background(Color("BrandPrimary").opacity(0.12))
                .clipShape(Circle())
        }
    }

    // For-Time larger nudge chips (e.g. -10s / +5s).
    private func quickAdjustButton(_ title: String, delta: Int) -> some View {
        Button(action: { adjustDuration(by: delta) }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("SecondaryText"))
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(Color("Surface2"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("Border"), lineWidth: 1)
                )
        }
    }

    private func adjustDuration(by delta: Int) {
        let current = draft.durationSeconds ?? 0
        draft.durationSeconds = max(0, current + delta)
    }

    /// Local copy of `WodTimerView.clockString` (that one is `private`).
    private func clockString(_ seconds: TimeInterval, showHours: Bool) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if showHours {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Previews

private func sampleWorkout(
    format: String,
    displayText: String,
    stimulus: String,
    constraintType: String,
    constraintMagnitude: Int,
    timeCap: Int? = nil
) -> HIITWorkoutItem {
    HIITWorkoutItem(
        id: Int.random(in: 1...10_000),
        format: format,
        displayText: displayText,
        stimulus: stimulus,
        constraintType: constraintType,
        constraintMagnitude: constraintMagnitude,
        timeCap: timeCap,
        timingScheme: nil,
        tags: [
            HIITWorkoutTag(id: 1, name: "Conditioning"),
            HIITWorkoutTag(id: 2, name: "Cardio")
        ]
    )
}

#Preview("For Time") {
    let workout = sampleWorkout(
        format: "For Time",
        displayText: "21-15-9 For Time:\nThrusters (95/65 lb)\nPull-ups",
        stimulus: "Lactic Threshold",
        constraintType: "time",
        constraintMagnitude: 45,
        timeCap: 600
    )
    return HIITWorkoutCompletionView(
        draft: WorkoutCompletionDraft(
            id: workout.id,
            workout: workout,
            capturedElapsed: 387
        ),
        onDone: { _ in },
        onSkip: { _ in }
    )
}

#Preview("AMRAP") {
    let workout = sampleWorkout(
        format: "AMRAP 20",
        displayText: "AMRAP 20:\n5 Pull-ups\n10 Push-ups\n15 Air Squats",
        stimulus: "Aerobic Capacity",
        constraintType: "rounds",
        constraintMagnitude: 20
    )
    return HIITWorkoutCompletionView(
        draft: WorkoutCompletionDraft(
            id: workout.id,
            workout: workout,
            capturedElapsed: 1200
        ),
        onDone: { _ in },
        onSkip: { _ in }
    )
}

#Preview("Submit failed") {
    let workout = sampleWorkout(
        format: "For Time",
        displayText: "21-15-9 For Time:\nThrusters (95/65 lb)\nPull-ups",
        stimulus: "Lactic Threshold",
        constraintType: "time",
        constraintMagnitude: 45
    )
    var draft = WorkoutCompletionDraft(id: workout.id, workout: workout, capturedElapsed: 387)
    draft.perceivedEffort = 8
    draft.notes = "Grip went early — broke the last set of pull-ups into threes."
    return HIITWorkoutCompletionView(
        draft: draft,
        errorMessage: "We couldn't save your result. Check your connection and try again.",
        onDone: { _ in },
        onSkip: { _ in },
        onDiscard: {}
    )
}

#Preview("Submitting") {
    let workout = sampleWorkout(
        format: "AMRAP 20",
        displayText: "AMRAP 20:\n5 Pull-ups\n10 Push-ups\n15 Air Squats",
        stimulus: "Aerobic Capacity",
        constraintType: "rounds",
        constraintMagnitude: 20
    )
    return HIITWorkoutCompletionView(
        draft: WorkoutCompletionDraft(id: workout.id, workout: workout, capturedElapsed: 1200),
        isSubmitting: true,
        onDone: { _ in },
        onSkip: { _ in }
    )
}

#Preview("EMOM (completion only)") {
    let workout = sampleWorkout(
        format: "EMOM 12",
        displayText: "EMOM 12:\nMin 1: 15 Cal Row\nMin 2: 12 Burpees\nMin 3: 15 KB Swings",
        stimulus: "Muscular Endurance",
        constraintType: "time",
        constraintMagnitude: 12
    )
    return HIITWorkoutCompletionView(
        draft: WorkoutCompletionDraft(
            id: workout.id,
            workout: workout,
            capturedElapsed: 720
        ),
        onDone: { _ in },
        onSkip: { _ in }
    )
}
