//
//  ConfettiView.swift
//  wodAI
//
//  Shared celebratory confetti overlay. Extracted from HIITWorkoutView so both
//  the workout feed and the completion screen use a single implementation.
//

import SwiftUI

struct ConfettiView: View {
    let onDismiss: () -> Void

    // @State, not `let`: a stored-property initializer re-runs every time the
    // enclosing view's body is re-evaluated, minting 60 fresh UUIDs. ForEach
    // keys off those ids, so every piece would be torn down and rebuilt — and
    // each new FallingShape's onAppear would replay the fall. That made the
    // confetti restart on any unrelated state change in the host view (typing a
    // note, picking an RPE). @State is initialized once per view identity and
    // survives re-renders, so the burst plays exactly once.
    @State private var pieces: [ConfettiPiece] = (0..<60).map { _ in ConfettiPiece() }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in FallingShape(piece: piece) }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { onDismiss() }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let delay: Double = Double.random(in: 0...0.8)
    let duration: Double = Double.random(in: 1.8...2.8)
    let size: CGFloat = CGFloat.random(in: 6...12)
    let rotation: Double = Double.random(in: 0...360)
    let rotationSpeed: Double = Double.random(in: 180...540)
    let color: Color = [Color("BrandPrimary"), Color("BrandSecondary"), .green, .yellow, .orange, .pink, .purple].randomElement()!
    let isCircle: Bool = Bool.random()
}

struct FallingShape: View {
    let piece: ConfettiPiece
    @State private var fallen = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if piece.isCircle {
                    Circle().fill(piece.color).frame(width: piece.size, height: piece.size)
                } else {
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.5)
                        .rotationEffect(.degrees(fallen ? piece.rotation + piece.rotationSpeed : piece.rotation))
                }
            }
            .position(x: geo.size.width * piece.x, y: fallen ? geo.size.height + 20 : -20)
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    fallen = true
                }
            }
        }
    }
}
