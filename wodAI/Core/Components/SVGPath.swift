//
//  SVGPath.swift
//  wodAI
//
//  Minimal SVG path-data parser: turns an SVG `d` string into a SwiftUI `Path`,
//  scaled to fit a rect while preserving aspect ratio.
//
//  This exists so body-map artwork stays *data* rather than structure. Swapping
//  the placeholder figure for the commissioned one is a string edit in
//  `BodyMapArt` — no codegen step, no code change, no rebuild of the view.
//  That is what keeps the illustration off the critical path.
//
//  Supports M/L/H/V/C/Q/Z in both absolute and relative forms. That is exactly
//  the subset the illustrator spec allows: no arcs, no transforms, no gradients,
//  no masks. Unsupported commands are skipped rather than trapped — a malformed
//  region should cost that one region, not crash the completion screen.
//

import SwiftUI

enum SVGPath {

    /// Parses `d` and returns a Path scaled to fit `rect`, preserving the
    /// aspect ratio of `viewBox` and centring within `rect`.
    static func path(from d: String, fitting rect: CGRect, viewBox: CGSize) -> Path {
        let raw = parse(d)
        guard viewBox.width > 0, viewBox.height > 0 else { return raw }

        let scale = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let dx = rect.minX + (rect.width - viewBox.width * scale) / 2
        let dy = rect.minY + (rect.height - viewBox.height * scale) / 2

        return raw.applying(
            CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)
        )
    }

    // MARK: - Parsing

    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    /// Builds a Path in the artwork's own viewBox coordinates.
    static func parse(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)

        var i = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        // Repeated coordinate pairs after a command implicitly repeat that
        // command (SVG allows "L10,10 20,20"), so the last command is sticky.
        var command: Character = "M"

        func nextNumber() -> CGFloat? {
            while i < tokens.count {
                if case .number(let n) = tokens[i] { i += 1; return n }
                return nil
            }
            return nil
        }

        func nextPoint(relative: Bool) -> CGPoint? {
            guard let x = nextNumber(), let y = nextNumber() else { return nil }
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while i < tokens.count {
            if case .command(let c) = tokens[i] {
                command = c
                i += 1
                if c == "Z" || c == "z" {
                    path.closeSubpath()
                    current = subpathStart
                    continue
                }
            }

            let relative = command.isLowercase
            switch Character(command.uppercased()) {
            case "M":
                guard let p = nextPoint(relative: relative) else { return path }
                path.move(to: p)
                current = p
                subpathStart = p
                // Per spec, extra pairs after a moveto are implicit linetos.
                command = relative ? "l" : "L"

            case "L":
                guard let p = nextPoint(relative: relative) else { return path }
                path.addLine(to: p)
                current = p

            case "H":
                guard let x = nextNumber() else { return path }
                let p = CGPoint(x: relative ? current.x + x : x, y: current.y)
                path.addLine(to: p)
                current = p

            case "V":
                guard let y = nextNumber() else { return path }
                let p = CGPoint(x: current.x, y: relative ? current.y + y : y)
                path.addLine(to: p)
                current = p

            case "C":
                guard let c1 = nextPoint(relative: relative),
                      let c2 = nextPoint(relative: relative),
                      let p = nextPoint(relative: relative) else { return path }
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p

            case "Q":
                guard let c = nextPoint(relative: relative),
                      let p = nextPoint(relative: relative) else { return path }
                path.addQuadCurve(to: p, control: c)
                current = p

            default:
                // Unknown command: drop the rest of this path rather than
                // emitting garbage geometry.
                return path
            }
        }

        return path
    }

    private static func tokenize(_ d: String) -> [Token] {
        var tokens: [Token] = []
        var number = ""

        func flush() {
            if !number.isEmpty {
                if let value = Double(number) { tokens.append(.number(CGFloat(value))) }
                number = ""
            }
        }

        for char in d {
            switch char {
            case "0"..."9", ".":
                number.append(char)
            case "-", "+":
                // A sign starts a new number unless it follows an exponent.
                if number.hasSuffix("e") || number.hasSuffix("E") {
                    number.append(char)
                } else {
                    flush()
                    number.append(char)
                }
            case "e", "E":
                number.append(char)
            case " ", ",", "\n", "\t", "\r":
                flush()
            default:
                flush()
                tokens.append(.command(char))
            }
        }
        flush()
        return tokens
    }
}
