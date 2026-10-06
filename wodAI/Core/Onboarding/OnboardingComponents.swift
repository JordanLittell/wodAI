//
//  OnboardingComponents.swift
//  wodAI
//
//  The few building blocks every onboarding step is made of.
//

import SwiftUI

/// A step's layout: a title, an optional subtitle, scrolling content, and a
/// footer pinned to the bottom.
struct OnboardingPage<Content: View, Footer: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("PrimaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(Color("SecondaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        // Content scrolls up under the footer and fades out behind it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background {
                LinearGradient(
                    stops: [.init(color: Color("Background").opacity(0), location: 0), .init(color: Color("Background"), location: 0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

extension OnboardingPage where Footer == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: subtitle, content: content, footer: { EmptyView() })
    }
}

/// Dims and shrinks a control slightly while it's pressed, so every tap
/// visibly lands.
struct OnboardingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A full-width choice: icon, title, optional subtitle. The whole card is the
/// tap target.
struct OnboardingOption: View {
    let icon: String
    let title: String
    var subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("PrimaryText"))
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color("BrandPrimary"))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(OnboardingPressStyle())
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// The main call to action at the bottom of a step.
struct OnboardingButton: View {
    let title: String
    var isEnabled = true
    var isBusy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isBusy ? 0 : 1)
                if isBusy { ProgressView().tint(.white) }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Capsule())
        }
        .buttonStyle(OnboardingPressStyle())
        .disabled(!isEnabled || isBusy)
    }
}

/// A small toggle pill for multi-select and short single-select lists.
struct OnboardingChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color("PrimaryText"))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(isSelected ? Color("BrandPrimary") : Color("Surface"), in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color("Border"), lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(OnboardingPressStyle())
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// A labeled number entry. Tapping anywhere on the row puts the cursor in
/// the field, not just on the digits.
struct OnboardingNumberField: View {
    let label: String
    var caption: String?
    @Binding var text: String
    let unit: String
    var keyboard: UIKeyboardType = .numberPad
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("PrimaryText"))
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }
            }
            .fixedSize()
            TextField("–", text: $text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .focused($focused)
            Text(unit).foregroundStyle(Color("SecondaryText"))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(focused ? Color("BrandPrimary") : Color("Border"), lineWidth: focused ? 2 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { focused = true }
        .animation(.easeOut(duration: 0.15), value: focused)
    }
}

/// The error under a step's button when a save fails.
struct OnboardingErrorText: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color("Error"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
    }
}

/// The thin bar across the top.
struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color("Surface2"))
                Capsule()
                    .fill(LinearGradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, geometry.size.width * progress))
            }
        }
        .frame(height: 6)
        .animation(.snappy(duration: 0.35), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}

/// Lays chips out left to right, wrapping onto new lines.
struct WrappingLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
