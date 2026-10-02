//
//  FloatingActionMenu.swift
//  wodAI
//
//  A round + button that floats over a page and opens a short list of
//  actions above itself. Adding an action is a new `QuickAction` case.
//

import SwiftUI

/// The actions the + menu offers, top to bottom.
enum QuickAction: CaseIterable, Identifiable {
    case createWithAI
    case importWhiteboard

    var id: Self { self }

    var title: String {
        switch self {
        case .createWithAI: return "Create with AI"
        case .importWhiteboard: return "Import from whiteboard"
        }
    }

    var systemImage: String {
        switch self {
        case .createWithAI: return "wand.and.stars"
        case .importWhiteboard: return "camera.viewfinder"
        }
    }
}

struct FloatingActionMenu: View {
    @Binding var isOpen: Bool
    var actions: [QuickAction] = QuickAction.allCases
    var isEnabled = true
    let onSelect: (QuickAction) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isOpen {
                ForEach(Array(actions.enumerated()), id: \.element) { index, action in
                    actionRow(action)
                        .transition(
                            .move(edge: .bottom)
                                .combined(with: .opacity)
                                .animation(.spring(duration: 0.3).delay(Double(index) * 0.04))
                        )
                }
            }

            Button {
                withAnimation(.spring(duration: 0.3)) { isOpen.toggle() }
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isOpen ? 45 : 0))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.brandPrimary))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)
            .accessibilityLabel(isOpen ? "Close menu" : "Add")
            .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        }
    }

    private func actionRow(_ action: QuickAction) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { isOpen = false }
            onSelect(action)
        } label: {
            HStack(spacing: 10) {
                Text(action.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("PrimaryText"))
                Image(systemName: action.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.brandPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color("Surface")))
            .overlay(Capsule().stroke(Color("Border"), lineWidth: 1))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

/// Dims the page behind an open `FloatingActionMenu`; a tap closes it.
struct FloatingActionScrim: View {
    @Binding var isOpen: Bool

    var body: some View {
        if isOpen {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) { isOpen = false }
                }
                .transition(.opacity)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    @Previewable @State var isOpen = true
    ZStack(alignment: .bottomTrailing) {
        Color("Background").ignoresSafeArea()
        FloatingActionScrim(isOpen: $isOpen)
        FloatingActionMenu(isOpen: $isOpen) { _ in }
            .padding(20)
    }
}
