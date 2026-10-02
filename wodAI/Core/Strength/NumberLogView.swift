//
//  NumberLogView.swift
//  wodAI
//
//  The NumberLog panel: a phone-style keypad for logging a set's weight or
//  reps. The top row shows the number being typed (with a kg/lb switch for
//  weight); Log saves it and checks the set off in one tap.
//

import SwiftUI
import UIKit

struct NumberLogView: View {
    let title: String
    let field: NumberLogField
    @Binding var input: NumberLogInput
    @Binding var unit: WeightUnit
    let canLog: Bool
    /// "Log" for a set; "Save" when the number isn't a set (e.g. a 1RM).
    var actionTitle: String = "Log"
    let onLog: () -> Void
    let onClose: () -> Void

    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("SecondaryText"))
                    .lineLimit(1)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "chevron.down")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("SecondaryText"))
                        .frame(width: 44, height: 32)
                }
                .accessibilityLabel("Close keypad")
            }

            display

            keypad

            logButton
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Color("Surface")
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Top row

    private var display: some View {
        HStack(spacing: 10) {
            Text(input.text.isEmpty ? placeholder : input.text)
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .foregroundColor(input.text.isEmpty ? Color("TertiaryText") : Color("PrimaryText"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("Background"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("BrandPrimary"), lineWidth: 1.5)
                )
                .accessibilityLabel(spokenValue)

            switch field {
            case .weight:
                Picker("Unit", selection: unitBinding) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 104)
            case .reps:
                Text("reps")
                    .font(.headline)
                    .foregroundColor(Color("SecondaryText"))
                    .frame(width: 104)
            }
        }
    }

    private var placeholder: String {
        field == .weight ? "BW" : "0"
    }

    private var spokenValue: String {
        guard let value = input.value else {
            return field == .weight ? "Bodyweight" : "No reps entered"
        }
        let number = value.formatted()
        return field == .weight ? "\(number) \(unit.spokenName)" : "\(number) reps"
    }

    /// Switching units converts what's typed, so the load stays the same.
    private var unitBinding: Binding<WeightUnit> {
        Binding(
            get: { unit },
            set: { newUnit in
                guard newUnit != unit else { return }
                if let value = input.value {
                    input.replaceText(newUnit.inputText(unit.toPounds(value)))
                }
                unit = newUnit
            }
        )
    }

    // MARK: - Keypad

    private var keypad: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { digit in
                        key(label: Text("\(digit)"), accessibility: "\(digit)") { input.press(digit) }
                    }
                }
            }
            GridRow {
                if field == .weight {
                    key(label: Text("."), accessibility: "Decimal point") { input.pressDecimal() }
                } else {
                    Color.clear
                }
                key(label: Text("0"), accessibility: "0") { input.press(0) }
                key(label: Image(systemName: "delete.left"), accessibility: "Delete") { input.delete() }
            }
        }
    }

    private func key<Label: View>(label: Label, accessibility: String, action: @escaping () -> Void) -> some View {
        Button {
            haptics.impactOccurred()
            action()
        } label: {
            label
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(Color("PrimaryText"))
                // Each key gets an equal cell of the panel, and the key itself
                // is the largest circle that fits in it, like a phone dialer.
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(Circle().fill(Color("Background")))
                .contentShape(Circle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyPressStyle())
        .accessibilityLabel(accessibility)
    }

    // MARK: - Log

    private var logButton: some View {
        Button(action: onLog) {
            HStack {
                Image(systemName: "checkmark")
                Text(actionTitle).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .opacity(canLog ? 1 : 0.4)
        }
        .disabled(!canLog)
    }
}

/// Keys dip and dim under the finger, so a press is felt even mid-set.
private struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var input = NumberLogInput(text: "185", allowsDecimal: true)
    @Previewable @State var unit = WeightUnit.lb
    VStack {
        Spacer()
        NumberLogView(
            title: "Set 2 · Back Squat",
            field: .weight,
            input: $input,
            unit: $unit,
            canLog: true,
            onLog: {},
            onClose: {}
        )
        .frame(height: 420)
    }
    .background(Color("Background"))
}
