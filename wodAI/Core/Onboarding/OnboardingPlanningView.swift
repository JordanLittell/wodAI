//
//  OnboardingPlanningView.swift
//  wodAI
//
//  The last onboarding screen: the server plans the athlete's first week while
//  this waits for today's session (OnboardingViewModel polls the run). The
//  status lines move with elapsed time only; they don't claim real progress.
//

import SwiftUI

struct OnboardingPlanningView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var appeared = Date()
    @State private var pulsing = false

    private static let statusLines = [
        "Looking at your goals",
        "Checking your equipment",
        "Choosing your movements",
        "Building today's session",
        "Planning the rest of your week",
    ]
    private static let secondsPerLine: TimeInterval = 8

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            badge
                .padding(.bottom, 32)

            switch viewModel.planWait {
            case .waiting, .ready:
                waiting
            case let .failed(message):
                failed(message)
            }
            Spacer()

            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            appeared = Date()
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { pulsing = true }
        }
    }

    private var isFailed: Bool {
        if case .failed = viewModel.planWait { return true }
        return false
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .opacity(0.18)
                .frame(width: 148, height: 148)
                .scaleEffect(pulsing && !isFailed ? 1.08 : 0.92)
            Circle()
                .fill(LinearGradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 104, height: 104)
            Image(systemName: isFailed ? "exclamationmark" : "calendar")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var waiting: some View {
        VStack(spacing: 12) {
            Text("Hang tight")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color("PrimaryText"))
            Text("We're planning your week. This usually takes a minute or two.")
                .font(.body)
                .foregroundStyle(Color("SecondaryText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            TimelineView(.periodic(from: appeared, by: 1)) { context in
                let index = min(Int(context.date.timeIntervalSince(appeared) / Self.secondsPerLine), Self.statusLines.count - 1)
                HStack(spacing: 8) {
                    ProgressView().tint(Color("BrandPrimary"))
                    Text(Self.statusLines[index] + "…")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("BrandPrimary"))
                        .contentTransition(.opacity)
                        .animation(.easeInOut, value: index)
                }
                .padding(.top, 12)
            }
        }
    }

    private func failed(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("We hit a snag")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color("PrimaryText"))
            Text(message)
                .font(.body)
                .foregroundStyle(Color("SecondaryText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.planWait {
        case .failed:
            VStack(spacing: 8) {
                OnboardingButton(title: "Try again", action: viewModel.retryPlan)
                secondaryButton("Continue anyway")
            }
        case .waiting(slow: true):
            VStack(spacing: 8) {
                Text("Taking a little longer than usual. We'll keep planning in the background.")
                    .font(.footnote)
                    .foregroundStyle(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
                OnboardingButton(title: "Continue to the app", action: viewModel.continueToApp)
            }
            .transition(.opacity)
        default:
            // Keeps the layout from jumping when a button appears.
            Color.clear.frame(height: 54)
        }
    }

    private func secondaryButton(_ title: String) -> some View {
        Button(action: viewModel.continueToApp) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("SecondaryText"))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(OnboardingPressStyle())
    }
}
