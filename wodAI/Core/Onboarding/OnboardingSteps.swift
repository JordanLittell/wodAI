//
//  OnboardingSteps.swift
//  wodAI
//
//  One view per onboarding step. Single-choice steps move on as soon as an
//  option is tapped; the rest move on only from their button at the bottom.
//

import SwiftUI

// MARK: - Goal

struct GoalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(title: "What are you training for?", subtitle: "We'll shape your workouts around it.") {
            VStack(spacing: 10) {
                ForEach(OnboardingGoal.all) { option in
                    OnboardingOption(
                        icon: option.icon,
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: viewModel.goal == option.goal
                    ) { viewModel.choose(option.goal) }
                }
            }
        }
    }
}

// MARK: - Experience

struct ExperienceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(title: "How long have you been training?") {
            VStack(spacing: 10) {
                ForEach(OnboardingExperience.allCases, id: \.self) { option in
                    OnboardingOption(
                        icon: option.icon,
                        title: option.title,
                        isSelected: viewModel.experience == option
                    ) { viewModel.choose(option) }
                }
            }
        }
    }
}

// MARK: - Schedule

struct ScheduleStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(title: "When do you want to rest?", subtitle: "We'll program every other day.") {
            VStack(alignment: .leading, spacing: 12) {
                label("Rest days")
                HStack(spacing: 4) {
                    ForEach(RestDay.allCases, id: \.self) { day in
                        dayButton(day)
                    }
                }
                Text("Rest days get an optional light activity.")
                    .font(.footnote)
                    .foregroundStyle(Color("SecondaryText"))
            }
            VStack(alignment: .leading, spacing: 12) {
                label("Minutes per session")
                HStack(spacing: 8) {
                    ForEach(OnboardingViewModel.sessionLengthOptions, id: \.self) { minutes in
                        OnboardingChip(title: "\(minutes) min", isSelected: viewModel.sessionLength == minutes) {
                            viewModel.sessionLength = minutes
                        }
                    }
                }
            }
        } footer: {
            OnboardingButton(title: "Continue", action: viewModel.saveSchedule)
        }
    }

    private func dayButton(_ day: RestDay) -> some View {
        let isSelected = viewModel.restDays.contains(day)
        return Button { viewModel.toggleRestDay(day) } label: {
            Text(day.displayName.prefix(1))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color("PrimaryText"))
                .frame(width: 42, height: 42)
                .background(isSelected ? Color("BrandPrimary") : Color("Surface"), in: Circle())
                .overlay(Circle().stroke(isSelected ? Color.clear : Color("Border")))
                // The whole slot is the tap target, not just the circle.
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(OnboardingPressStyle())
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(isSelected ? "\(day.displayName), rest day" : day.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("SecondaryText"))
    }
}

// MARK: - Gym

struct GymStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(title: "Where do you train?", subtitle: "You can fine-tune the equipment next.") {
            VStack(spacing: 10) {
                ForEach(viewModel.content.gymPresets) { preset in
                    OnboardingOption(
                        icon: icon(for: preset.id),
                        title: preset.name,
                        isSelected: viewModel.gymPreset == preset
                    ) { viewModel.choose(preset) }
                }
            }
        }
    }

    private func icon(for preset: String) -> String {
        switch preset {
        case "crossfit_box": return "figure.cross.training"
        case "commercial_gym": return "building.2"
        case "home_gym": return "house"
        case "bodyweight": return "figure.walk"
        default: return "dumbbell"
        }
    }
}

// MARK: - Equipment

struct EquipmentStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(title: "Your equipment", subtitle: "Tap anything to add or remove it.") {
            WrappingLayout(spacing: 8) {
                ForEach(viewModel.allEquipment) { item in
                    OnboardingChip(title: item.name, isSelected: viewModel.equipmentIds.contains(item.id)) {
                        viewModel.toggleEquipment(item.id)
                    }
                }
            }
        } footer: {
            OnboardingButton(title: "Continue", action: viewModel.saveEquipment)
        }
    }
}

// MARK: - Skill questions

struct SkillStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    /// The question this screen shows, so a tap that lands while it slides
    /// away can't answer the next one.
    let step: OnboardingStep

    var body: some View {
        if let shown = viewModel.question(at: step) {
            let ladder = shown.ladder, question = shown.rung
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(ladder.domain) · \(ladder.name)".uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(Color("BrandPrimary"))
                    Text(question.question)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("PrimaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("We start hard and work down. Say yes to the first one you can do.")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        answer("No", isYes: false)
                        answer("Yes", isYes: true)
                    }
                    Button { viewModel.skipLadder(at: step) } label: {
                        Text("Skip this one")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color("SecondaryText"))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(OnboardingPressStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }

    private func answer(_ title: String, isYes: Bool) -> some View {
        Button { viewModel.answer(isYes, to: step) } label: {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isYes ? Color.white : Color("PrimaryText"))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background {
                    if isYes {
                        Capsule().fill(LinearGradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")], startPoint: .leading, endPoint: .trailing))
                    } else {
                        Capsule().fill(Color("Surface")).overlay(Capsule().stroke(Color("Border")))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(OnboardingPressStyle())
    }
}

// MARK: - Lifts

struct LiftsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(
            title: "Your one-rep maxes",
            subtitle: "Optional. The most you've lifted for a single rep. We'll use these to pick your weights."
        ) {
            VStack(spacing: 10) {
                ForEach(viewModel.content.lifts) { lift in
                    OnboardingNumberField(
                        label: lift.name,
                        caption: "1RM",
                        text: Binding(
                            get: { viewModel.oneRepMaxes[lift.id] ?? "" },
                            set: { viewModel.oneRepMaxes[lift.id] = $0 }
                        ),
                        unit: "lb",
                        keyboard: .decimalPad
                    )
                }
            }
        } footer: {
            OnboardingButton(
                title: viewModel.hasOneRepMaxes ? "Continue" : "Skip",
                isEnabled: viewModel.oneRepMaxesAreValid,
                action: viewModel.saveLifts
            )
        }
    }
}

// MARK: - About you

struct AboutYouStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingPage(title: "A little about you", subtitle: "Optional. Helps us estimate calories and heart-rate zones.") {
            WrappingLayout(spacing: 8) {
                ForEach(OnboardingSex.allCases, id: \.self) { option in
                    OnboardingChip(title: option.title, isSelected: viewModel.sex == option) {
                        viewModel.sex = viewModel.sex == option ? nil : option
                    }
                }
            }
            VStack(spacing: 10) {
                OnboardingNumberField(label: "Age", text: $viewModel.age, unit: "years")
                HStack(spacing: 10) {
                    OnboardingNumberField(label: "Height", text: $viewModel.heightFeet, unit: "ft")
                    OnboardingNumberField(label: "", text: $viewModel.heightInches, unit: "in")
                }
                OnboardingNumberField(label: "Weight", text: $viewModel.bodyWeight, unit: "lb")
            }
        } footer: {
            OnboardingErrorText(message: viewModel.errorMessage)
            OnboardingButton(
                title: "Finish",
                isEnabled: viewModel.aboutYouIsValid,
                isBusy: viewModel.isFinishing,
                action: viewModel.finish
            )
        }
    }
}
