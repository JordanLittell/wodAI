//
//  LineAdjustSheet.swift
//  wodAI
//
//  What a tap on a line's count or load opens: one number in the line's own
//  unit, typed or stepped (+/-), saved with adjustHiitLine. Units never change
//  here (a swap converts them); a load added where none was written takes lb
//  for a weight or in for a box, as the server saves it. A load can be removed.
//

import SwiftUI

/// The line and which of its numbers is being adjusted; drives the sheet.
struct LineAdjustTarget: Identifiable {
    let line: HIITLine
    let field: HIITLineField

    var id: String { "\(line.id)-\(field)" }
}

struct LineAdjustSheet: View {
    let line: HIITLine
    let field: HIITLineField
    /// Called with the new value, or nil to remove the load.
    let onSave: (Double?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    @FocusState private var focused: Bool

    init(line: HIITLine, field: HIITLineField, onSave: @escaping (Double?) -> Void) {
        self.line = line
        self.field = field
        self.onSave = onSave
        let current = field == .amount ? line.amount : line.load
        self._value = State(initialValue: current ?? Self.startingLoad(for: line))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    stepButton("minus", by: -step)
                        .disabled(value - step <= 0)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        TextField("0", value: $value, format: .number)
                            .keyboardType(wholeNumbers ? .numberPad : .decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
                            .foregroundColor(Color("PrimaryText"))
                            .focused($focused)
                            .fixedSize()
                        Text(unitLabel)
                            .font(.title3)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    .frame(maxWidth: .infinity)
                    stepButton("plus", by: step)
                }
                .padding(.horizontal)

                if field == .load, line.load != nil {
                    Button("Remove load", role: .destructive) {
                        onSave(nil)
                        dismiss()
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 12)
            .navigationTitle(line.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(saved)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func stepButton(_ symbol: String, by delta: Double) -> some View {
        Button {
            focused = false
            value = max(step, ((value + delta) / step).rounded() * step)
        } label: {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(Color("Surface"))
                .clipShape(Circle())
        }
        .foregroundColor(Color("BrandPrimary"))
        .accessibilityLabel(delta < 0 ? "Less" : "More")
    }

    private var step: Double { line.step(for: field) }

    /// Reps and calories are whole; the server rounds them too.
    private var wholeNumbers: Bool { field == .amount && ["reps", "cal"].contains(line.amountUnit) }

    private var saved: Double { wholeNumbers ? value.rounded() : (value * 100).rounded() / 100 }

    private var canSave: Bool {
        guard value.isFinite, saved > 0 else { return false }
        let current = field == .amount ? line.amount : line.load
        return saved != current
    }

    private var unitLabel: String {
        switch field {
        case .amount:
            switch line.amountUnit {
            case "reps": return "reps"
            case "cal": return "Cal"
            default: return line.amountUnit
            }
        case .load:
            return line.loadUnit ?? (line.loads.contains("weight") ? "lb" : "in")
        }
    }

    /// Where a load starts when none is written: a light barbell, or a 20 in box.
    private static func startingLoad(for line: HIITLine) -> Double {
        line.loads.contains("weight") ? 45 : 20
    }
}

#Preview("Amount") {
    LineAdjustSheet(
        line: HIITLine(line: 1, partId: nil, exerciseId: 1, name: "Thruster", patterns: "", amount: 21,
                       amountUnit: "reps", max: false, load: 95, loadUnit: "lb", loads: ["weight"]),
        field: .amount
    ) { _ in }
}

#Preview("Add a load") {
    LineAdjustSheet(
        line: HIITLine(line: 1, partId: nil, exerciseId: 1, name: "Box Jump", patterns: "", amount: 10,
                       amountUnit: "reps", max: false, load: nil, loadUnit: nil, loads: ["height"]),
        field: .load
    ) { _ in }
}
