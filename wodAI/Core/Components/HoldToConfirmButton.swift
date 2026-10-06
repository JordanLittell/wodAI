//
//  HoldToConfirmButton.swift
//  wodAI
//
//  A button that requires a sustained press (default 2s) before it fires, with
//  a progress fill and haptics. Guards disruptive actions (resume / finish)
//  against accidental taps.
//

import SwiftUI
import UIKit

struct HoldToConfirmButton: View {
    enum Style {
        /// Brand gradient background (primary / resume actions).
        case gradient
        /// Solid color background (e.g. finish).
        case solid(Color)
    }

    let title: String
    let systemImage: String
    var style: Style = .gradient
    var holdDuration: Double = 2.0
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var workItem: DispatchWorkItem?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundColor(.white)
        .background(baseBackground)
        .overlay(fillOverlay)
        .cornerRadius(14)
        .shadow(color: shadowColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .scaleEffect(isHolding ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHolding)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isHolding { begin() } }
                .onEnded { _ in cancel() }
        )
        .accessibilityLabel("Hold to \(title.lowercased())")
    }

    // MARK: - Appearance

    @ViewBuilder
    private var baseBackground: some View {
        switch style {
        case .gradient:
            LinearGradient(
                colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                startPoint: .leading, endPoint: .trailing
            )
        case .solid(let color):
            color
        }
    }

    private var shadowColor: Color {
        switch style {
        case .gradient: return Color("BrandPrimary")
        case .solid(let color): return color
        }
    }

    private var fillOverlay: some View {
        GeometryReader { geo in
            Color.white.opacity(0.35)
                .frame(width: geo.size.width * progress)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Hold lifecycle

    private func begin() {
        isHolding = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.linear(duration: holdDuration)) { progress = 1 }

        let item = DispatchWorkItem { complete() }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: item)
    }

    private func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        action()
        reset()
    }

    private func cancel() {
        workItem?.cancel()
        workItem = nil
        reset()
    }

    private func reset() {
        isHolding = false
        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
    }
}
