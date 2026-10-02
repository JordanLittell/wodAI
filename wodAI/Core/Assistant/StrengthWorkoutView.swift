//
//  StrengthWorkoutView.swift
//  wodAI
//
//  Destination for a session's strength block. A two-half header (how-to
//  media, and the current exercise's working 1RM and last weight at each prescribed RPE), then
//  one row per set showing its weight and reps. Tapping a value, or the 1RM,
//  opens the NumberLog keypad over the bottom half of the screen. For a set,
//  Log records the number and checks the set off, then moves the keypad on to
//  the next set.
//

import SwiftUI

struct StrengthWorkoutView: View {
    let workout: StrengthWorkout
    @StateObject private var viewModel: StrengthWorkoutViewModel
    @ObservedObject private var stats = ExerciseStatsStore.shared

    /// What the keypad is editing; nil when the keypad is closed.
    @State private var target: KeypadTarget?
    @State private var input = NumberLogInput(text: "", allowsDecimal: false)
    @AppStorage("weightUnit") private var unit: WeightUnit = .lb

    private enum KeypadTarget: Equatable {
        /// A set's weight or reps, by index into `viewModel.sets`.
        case set(index: Int, field: NumberLogField)
        /// An exercise's working 1RM.
        case oneRepMax(exercise: String)
    }

    /// `onChange` receives the block after each saved set, so the owner's
    /// copy stays current for when the block is reopened.
    init(workout: StrengthWorkout, onChange: ((StrengthWorkout) -> Void)? = nil) {
        self.workout = workout
        self._viewModel = StateObject(wrappedValue: StrengthWorkoutViewModel(workout: workout, onChange: onChange))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                List {
                    if let exercise = viewModel.headerExercise {
                        Section {
                            ExerciseSummaryHeader(
                                exercise: exercise,
                                muscleGroups: viewModel.muscleGroups(for: exercise),
                                oneRepMax: stats.oneRepMax(for: exercise),
                                tracksOneRepMax: viewModel.tracksOneRepMax(exercise),
                                unit: unit,
                                onEditOneRepMax: { openOneRepMax(exercise) }
                            )
                            // A new identity per exercise, so switching (e.g.
                            // Front Squat to Pendlay Row in a superset)
                            // crossfades rather than morphing text in place.
                            .id(exercise)
                            .transition(.opacity)
                        }
                    }

                    Section {
                        ForEach(viewModel.sets.indices, id: \.self) { index in
                            SetRow(
                                number: index + 1,
                                set: viewModel.sets[index],
                                entry: viewModel.entry(for: index),
                                lastWeight: viewModel.lastWeight(forSet: index),
                                done: viewModel.completed[index] != nil,
                                isCurrent: index == viewModel.currentIndex,
                                editing: editingField(index),
                                unit: unit,
                                onSelect: { open(index, $0) },
                                onToggle: {
                                    select(index)
                                    viewModel.toggleComplete(index)
                                }
                            )
                            .id(index)
                            // Tapping anywhere else on the row selects it too;
                            // the chips and check are borderless buttons, so
                            // they still get their own taps first.
                            .contentShape(Rectangle())
                            .onTapGesture { select(index) }
                            .listRowBackground(
                                viewModel.selectedIndex == index ? Color("BrandPrimary").opacity(0.08) : nil
                            )
                            .accessibilityAddTraits(viewModel.selectedIndex == index ? .isSelected : [])
                        }
                    } footer: {
                        if let syncError = viewModel.syncError {
                            Label(syncError, systemImage: "exclamationmark.triangle")
                                .foregroundColor(Color("Error"))
                        } else if viewModel.isFinished {
                            Text("All sets done.")
                        }
                    }
                }
                // Keep the row being logged (or, with the keypad closed, the
                // next set) in view as the athlete works down the list.
                .onChange(of: target) { _, target in
                    guard case let .set(index, _) = target else { return }
                    withAnimation { proxy.scrollTo(index, anchor: .center) }
                }
                .onChange(of: viewModel.currentIndex) { _, next in
                    guard target == nil, let next else { return }
                    withAnimation { proxy.scrollTo(next, anchor: .center) }
                }
                // An inset rather than an overlay: the list shrinks to the top
                // half instead of hiding rows behind the keypad.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if let target {
                        keypad(for: target)
                            .frame(height: geo.size.height * 0.5)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: target != nil)
        // Small centered title. The principal slot gets all the bar's width
        // between the back chevron and the trailing edge (a leading item is
        // squeezed to its minimum). `.navigationTitle` is still set for the
        // back-button label and VoiceOver; the principal view replaces its display.
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        // Opened mid-generation, the block has no server ids; when the saved
        // session lands, hand them over so logged sets reach the server.
        .onChange(of: workout.serverId) { _, _ in
            viewModel.adoptSaved(workout)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(workout.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("PrimaryText"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    // MARK: - Keypad

    @ViewBuilder
    private func keypad(for target: KeypadTarget) -> some View {
        switch target {
        case let .set(index, field):
            NumberLogView(
                title: "Set \(index + 1) · \(viewModel.sets[index].exercise.name)",
                field: field,
                input: $input,
                unit: $unit,
                canLog: canLog(index, field),
                onLog: { log(index, field) },
                onClose: close
            )
        case let .oneRepMax(exercise):
            NumberLogView(
                title: "Working 1RM · \(exercise)",
                field: .weight,
                input: $input,
                unit: $unit,
                // Blank saves as "clear it", so there's always something to save.
                canLog: true,
                actionTitle: "Save",
                onLog: { saveOneRepMax(exercise) },
                onClose: close
            )
        }
    }

    private func editingField(_ index: Int) -> NumberLogField? {
        guard case let .set(i, field) = target, i == index else { return nil }
        return field
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.25)) { target = nil }
    }

    /// Opening (or switching to) a value starts from what the row shows.
    /// Anything typed for a previous value and not logged is dropped.
    /// Show this set's exercise in the header.
    private func select(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.select(index)
        }
    }

    private func open(_ index: Int, _ field: NumberLogField) {
        select(index)
        let entry = viewModel.entry(for: index)
        switch field {
        case .weight:
            input = NumberLogInput(text: entry.weight.map(unit.inputText) ?? "", allowsDecimal: true)
        case .reps:
            input = NumberLogInput(text: entry.reps.map(String.init) ?? "", allowsDecimal: false)
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            target = .set(index: index, field: field)
        }
    }

    private func openOneRepMax(_ exercise: String) {
        input = NumberLogInput(text: stats.oneRepMax(for: exercise).map(unit.inputText) ?? "", allowsDecimal: true)
        withAnimation(.easeInOut(duration: 0.25)) {
            target = .oneRepMax(exercise: exercise)
        }
    }

    /// An untouched prefill saves the stored value itself, so opening in kg
    /// and tapping Save doesn't round it.
    private func saveOneRepMax(_ exercise: String) {
        if !input.isPristine {
            stats.setOneRepMax(input.value.map(unit.toPounds), for: exercise)
        }
        close()
    }

    /// A set can't be logged with no reps; editing the weight of a set whose
    /// reps are blank is the only way that happens.
    private func canLog(_ index: Int, _ field: NumberLogField) -> Bool {
        (reps(index, field) ?? 0) > 0
    }

    private func reps(_ index: Int, _ field: NumberLogField) -> Int? {
        switch field {
        case .reps: return input.value.map { Int($0) }
        case .weight: return viewModel.entry(for: index).reps
        }
    }

    /// The weight to record, in pounds. An untouched prefill is logged as the
    /// stored value itself, so opening in kg and tapping Log doesn't round it.
    private func weight(_ index: Int, _ field: NumberLogField) -> Double? {
        switch field {
        case .reps:
            return viewModel.entry(for: index).weight
        case .weight:
            if input.isPristine { return viewModel.entry(for: index).weight }
            return input.value.map(unit.toPounds)
        }
    }

    private func log(_ index: Int, _ field: NumberLogField) {
        guard let reps = reps(index, field), reps > 0 else { return }
        viewModel.log(index, weight: weight(index, field), reps: reps)

        if let next = viewModel.nextIncomplete(after: index) {
            open(next, field)
        } else {
            close()
        }
    }
}

// MARK: - Set row

/// One set: what was prescribed, and the weight and reps to log as tappable
/// chips. The chips are outlined so it's clear from the row itself that the
/// numbers are the athlete's to change.
private struct SetRow: View {
    let number: Int
    let set: StrengthComponent
    let entry: SetEntry
    /// Pounds last logged for this same effort (exercise, reps, RPE). Nil
    /// when there's no history, and then nothing is shown.
    let lastWeight: Double?
    let done: Bool
    let isCurrent: Bool
    /// Which of this row's values the keypad is editing, if any.
    let editing: NumberLogField?
    let unit: WeightUnit
    let onSelect: (NumberLogField) -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Set \(number) · \(set.exercise.name)")
                    .font(.body.weight(isCurrent ? .semibold : .regular))
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target \(targetText)")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    // Hidden once the set is done: its own chip then shows
                    // what was lifted, which is also what "last" would say.
                    if let lastWeight, !done {
                        Text("Last \(unit.format(lastWeight)) \(unit.rawValue)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("BrandPrimary"))
                            .accessibilityLabel("Last time, \(unit.format(lastWeight)) \(unit.spokenName)")
                    }
                }
            }

            HStack(spacing: 8) {
                chip(
                    value: entry.weight.map(unit.format) ?? "BW",
                    unit: entry.weight == nil ? "" : unit.rawValue,
                    field: .weight,
                    accessibility: entry.weight.map { "Weight, \(unit.format($0)) \(unit.spokenName)" } ?? "Weight, bodyweight"
                )
                Text("×")
                    .foregroundColor(Color("SecondaryText"))
                chip(
                    value: entry.reps.map(String.init) ?? "–",
                    unit: "reps",
                    field: .reps,
                    accessibility: "Reps, \(entry.reps.map(String.init) ?? "none")"
                )
                Spacer()
                Button(action: onToggle) {
                    Image(systemName: done ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 30))
                        .foregroundColor(done || isCurrent ? Color("BrandPrimary") : Color("TertiaryText"))
                }
                // Borderless: in a List row a plain Button would make the
                // whole row (including the chips) toggle it.
                .buttonStyle(.borderless)
                .accessibilityLabel(done ? "Mark set \(number) not done" : "Mark set \(number) done")
            }
        }
        .padding(.vertical, 6)
        .opacity(done && !isCurrent && editing == nil ? 0.7 : 1)
    }

    private func chip(value: String, unit: String, field: NumberLogField, accessibility: String) -> some View {
        let isEditing = editing == field
        return Button { onSelect(field) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .foregroundColor(Color("PrimaryText"))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .frame(minWidth: 72)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color("Surface"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditing || isCurrent ? Color("BrandPrimary") : Color("Border"), lineWidth: isEditing ? 2 : 1)
            )
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibility)
        .accessibilityHint("Opens the keypad to log it")
    }

    /// Prescription in the chosen unit, e.g. "5 × 185 lb · RPE 7", or "10 reps".
    private var targetText: String {
        var text = set.weight.map { "\(set.reps) × \(unit.format($0)) \(unit.rawValue)" } ?? "\(set.reps) reps"
        if let rpe = set.rpe { text += " · RPE \(rpe)" }
        return text
    }
}

#Preview {
    NavigationStack {
        StrengthWorkoutView(workout: StrengthWorkout(
            id: 1, name: "Back Squat",
            instructions: "Rest 2-3 minutes between sets. Build to the heavier triples.",
            components: [
                StrengthComponent(order: 0, reps: 5, weight: 185, rpe: 6, exercise: ExerciseName(name: "Back Squat", muscleGroups: ["Quads", "Glutes", "Adductors"])),
                StrengthComponent(order: 1, reps: 3, weight: 205, rpe: 7, exercise: ExerciseName(name: "Back Squat", muscleGroups: ["Quads", "Glutes", "Adductors"])),
                StrengthComponent(order: 2, reps: 3, weight: nil, rpe: 8, exercise: ExerciseName(name: "Back Squat", muscleGroups: ["Quads", "Glutes", "Adductors"])),
                StrengthComponent(order: 3, reps: 10, weight: nil, rpe: nil, exercise: ExerciseName(name: "Pull-up")),
            ]
        ))
    }
}

#Preview("Superset") {
    NavigationStack {
        StrengthWorkoutView(workout: StrengthWorkout(
            id: 2, name: "Front Squat + Pendlay Row",
            instructions: "",
            components: [
                StrengthComponent(order: 0, reps: 5, weight: 155, rpe: 7, exercise: ExerciseName(name: "Front Squat", muscleGroups: ["Quads", "Glutes", "Upper Back"])),
                StrengthComponent(order: 1, reps: 8, weight: 135, rpe: 7, exercise: ExerciseName(name: "Pendlay Row", muscleGroups: ["Lats", "Rhomboids", "Rear Delts"])),
                StrengthComponent(order: 2, reps: 5, weight: 155, rpe: 7, exercise: ExerciseName(name: "Front Squat", muscleGroups: ["Quads", "Glutes", "Upper Back"])),
                StrengthComponent(order: 3, reps: 8, weight: 135, rpe: 7, exercise: ExerciseName(name: "Pendlay Row", muscleGroups: ["Lats", "Rhomboids", "Rear Delts"])),
            ]
        ))
    }
}
