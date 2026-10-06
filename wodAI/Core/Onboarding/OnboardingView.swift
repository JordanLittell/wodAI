//
//  OnboardingView.swift
//  wodAI
//
//  New athletes land here after signing up (ContentView routes on
//  AuthState.needsProvisioning). One short question per screen under a
//  progress bar: goal, experience, schedule, gym, equipment, skill questions,
//  lifts, and a little about them. Each step saves as they go.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            switch viewModel.phase {
            case .loading:
                ProgressView().tint(Color("BrandPrimary"))
            case .failed:
                retry
            case .planning:
                OnboardingPlanningView(viewModel: viewModel)
                    .transition(.opacity)
            case .ready:
                VStack(spacing: 0) {
                    topBar
                    step
                        .id(viewModel.flow.current)
                        .transition(.asymmetric(
                            insertion: .move(edge: viewModel.movingForward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: viewModel.movingForward ? .leading : .trailing).combined(with: .opacity)
                        ))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .clipped()
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
        .sensoryFeedback(.selection, trigger: viewModel.flow.current)
        .task { await viewModel.load() }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color("PrimaryText"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Back")
            .opacity(viewModel.flow.canGoBack ? 1 : 0)
            .disabled(!viewModel.flow.canGoBack)

            OnboardingProgressBar(progress: viewModel.flow.progress)

            // Balances the back button so the bar sits centered.
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var step: some View {
        switch viewModel.flow.current {
        case .goal: GoalStep(viewModel: viewModel)
        case .experience: ExperienceStep(viewModel: viewModel)
        case .schedule: ScheduleStep(viewModel: viewModel)
        case .gym: GymStep(viewModel: viewModel)
        case .equipment: EquipmentStep(viewModel: viewModel)
        case let .skill(ladder, rung): SkillStep(viewModel: viewModel, step: .skill(ladder: ladder, rung: rung))
        case .lifts: LiftsStep(viewModel: viewModel)
        case .aboutYou: AboutYouStep(viewModel: viewModel)
        }
    }

    private var retry: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(Color("SecondaryText"))
            Text("Couldn't get started")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("PrimaryText"))
            Text("Check your connection and try again.")
                .foregroundStyle(Color("SecondaryText"))
            OnboardingButton(title: "Try again") { Task { await viewModel.load() } }
                .frame(maxWidth: 240)
                .padding(.top, 8)
        }
        .padding(24)
    }
}

#Preview {
    OnboardingView()
}
