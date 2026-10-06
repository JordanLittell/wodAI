//
//  NumberLogInput.swift
//  wodAI
//
//  The pure, SwiftUI-free half of the NumberLog keypad: weight units and the
//  typing rules for the number being entered. Kept separate so the rules are
//  unit-tested rather than poked at in the simulator.
//

import Foundation

/// How weights are shown and typed. Storage is always pounds (the backend's
/// unit); this only converts at the edges.
enum WeightUnit: String, CaseIterable, Identifiable {
    case lb, kg

    static let poundsPerKilogram = 2.20462

    var id: String { rawValue }

    /// Spoken form for VoiceOver.
    var spokenName: String { self == .lb ? "pounds" : "kilograms" }

    func toPounds(_ value: Double) -> Double {
        self == .lb ? value : value * Self.poundsPerKilogram
    }

    func fromPounds(_ pounds: Double) -> Double {
        self == .lb ? pounds : pounds / Self.poundsPerKilogram
    }

    /// A stored (pound) weight for display in this unit: "185", "83.9".
    func format(_ pounds: Double) -> String {
        fromPounds(pounds).formatted(.number.precision(.fractionLength(0...1)).grouping(.never))
    }

    /// A stored (pound) weight as keypad text in this unit. Always "." as the
    /// decimal separator, since that's what the keypad types.
    func inputText(_ pounds: Double) -> String {
        fromPounds(pounds).formatted(
            .number.precision(.fractionLength(0...1)).grouping(.never).locale(Locale(identifier: "en_US_POSIX"))
        )
    }
}

/// Which value on a set the keypad is editing.
enum NumberLogField: Equatable {
    case weight, reps
}

/// The number being typed on the keypad.
///
/// It opens showing the set's current value. The first key pressed replaces
/// that value, as on a calculator, so logging "205" over a prefilled "185"
/// is three taps rather than three deletes and three digits.
struct NumberLogInput: Equatable {
    private(set) var text: String
    let allowsDecimal: Bool
    /// True until the first key press: the value is still the prefill.
    private(set) var isPristine = true

    private static let maxDecimals = 2

    init(text: String, allowsDecimal: Bool) {
        self.text = text
        self.allowsDecimal = allowsDecimal
    }

    /// Weight: "1234.5" fits. Reps: up to 999.
    private var maxLength: Int { allowsDecimal ? 6 : 3 }

    /// Blank is nil (bodyweight, for a weight). A trailing "." still reads as
    /// the whole number typed so far.
    var value: Double? {
        let trimmed = text.hasSuffix(".") ? String(text.dropLast()) : text
        return trimmed.isEmpty ? nil : Double(trimmed)
    }

    mutating func press(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        takeOverPrefill()
        if let dot = text.firstIndex(of: "."), text[text.index(after: dot)...].count >= Self.maxDecimals {
            return
        }
        // "0" followed by a digit is that digit: no leading zeros.
        let next = text == "0" ? String(digit) : text + String(digit)
        guard next.count <= maxLength else { return }
        text = next
    }

    mutating func pressDecimal() {
        guard allowsDecimal else { return }
        takeOverPrefill()
        guard !text.contains(".") else { return }
        let next = text.isEmpty ? "0." : text + "."
        guard next.count <= maxLength else { return }
        text = next
    }

    /// Removes the last character; on the untouched prefill, clears it.
    mutating func delete() {
        if isPristine {
            takeOverPrefill()
            return
        }
        if !text.isEmpty { text.removeLast() }
    }

    /// Swap the displayed text (e.g. converting between kg and lb) without
    /// counting as a key press.
    mutating func replaceText(_ newText: String) {
        text = newText
    }

    private mutating func takeOverPrefill() {
        if isPristine {
            text = ""
            isPristine = false
        }
    }
}
