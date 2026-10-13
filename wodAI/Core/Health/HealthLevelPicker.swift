//
//  HealthLevelPicker.swift
//  wodAI
//
//  "Here's what we found": why Health suggests a level, and the levels to
//  pick from, the suggestion marked. Used by onboarding's Apple Health step
//  and the Apple Health screen. The athlete always confirms; nothing is set
//  from Health on its own.
//

import SwiftUI

struct HealthLevelPicker: View {
    let suggestion: HealthSuggestion
    @Binding var selection: OnboardingLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !suggestion.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(suggestion.reasons, id: \.self) { reason in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "heart.text.square")
                                .foregroundStyle(Color("BrandPrimary"))
                            Text(reason)
                                .font(.subheadline)
                                .foregroundStyle(Color("PrimaryText"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 14))
            }

            VStack(spacing: 10) {
                ForEach(OnboardingLevel.allCases, id: \.self) { level in
                    OnboardingOption(
                        icon: level == suggestion.level ? "sparkles" : "circle.dashed",
                        title: level.title,
                        subtitle: level == suggestion.level ? "Suggested" : nil,
                        isSelected: selection == level
                    ) { selection = level }
                }
            }
        }
    }
}
