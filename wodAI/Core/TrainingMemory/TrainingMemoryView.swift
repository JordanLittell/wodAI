//
//  TrainingMemoryView.swift
//  wodAI
//
//  Your training (menu: Training): what the coach keeps to in every session
//  it programs. A focus block with its week, habits, and things to leave
//  out. Items are added in the coach chat once the athlete says yes; here
//  they're corrected or removed. Tapping an item opens MemoryItemEditSheet.
//  Kept off the Workout page on purpose, so the week stays about the week.
//

import SwiftUI

struct TrainingMemoryView: View {
    @StateObject private var viewModel: TrainingMemoryViewModel
    @State private var editing: TrainingMemoryItem?

    init() {
        _viewModel = StateObject(wrappedValue: TrainingMemoryViewModel())
    }

    init(viewModel: @autoclosure @escaping () -> TrainingMemoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            if !viewModel.hasLoaded && viewModel.loadError == nil {
                ProgressView()
                    .tint(Color("BrandPrimary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.loadError {
                errorCard(error)
            } else {
                content
            }
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle("Your training")
        .navigationBarTitleDisplayMode(.inline)
        // Every visit reloads: the coach may have kept something new since.
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $editing) { item in
            MemoryItemEditSheet(item: item, viewModel: viewModel)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.memory.isEmpty {
                    emptyState
                } else {
                    if let focus = viewModel.memory.focus {
                        section(title: "Focus", subtitle: "What your sessions build toward. The last week is a de-load, then a test.") {
                            FocusCard(item: focus, isBusy: viewModel.busyId == focus.id) { editing = focus }
                        }
                    }
                    if !viewModel.memory.habits.isEmpty {
                        section(title: "Every session", subtitle: "Included every time the coach programs for you.") {
                            ForEach(viewModel.memory.habits) { item in
                                MemoryRow(item: item, icon: "checkmark.circle", isBusy: viewModel.busyId == item.id) { editing = item }
                            }
                        }
                    }
                    if !viewModel.memory.avoid.isEmpty {
                        section(title: "Leave out", subtitle: "Kept out of every session.") {
                            ForEach(viewModel.memory.avoid) { item in
                                MemoryRow(item: item, icon: "nosign", isBusy: viewModel.busyId == item.id) { editing = item }
                            }
                        }
                    }
                    Text("Tell the coach what else to keep to. It asks before adding anything here.")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                }
            }
            .padding()
            .padding(.bottom, 32)
        }
    }

    private func section<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("SecondaryText"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
            }
            content()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundColor(Color("BrandPrimary"))
            Text("Nothing kept yet")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            Text("Tell the coach how you like to train, like a warmup every session, a movement to skip, or a lift to focus on for a few weeks. Once you say yes, it shows up here and in every session the coach programs.")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color("Warning"))
            Text("Unable to load your training")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
            Button("Try Again") { Task { await viewModel.load() } }
                .foregroundColor(Color("BrandPrimary"))
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Focus card

private struct FocusCard: View {
    let item: TrainingMemoryItem
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.text)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                        .multilineTextAlignment(.leading)
                    if let line = item.stageLine(on: Date()) {
                        Text(line)
                            .font(.subheadline)
                            .foregroundColor(item.stage(on: Date()) == .finished ? Color("Warning") : Color("SecondaryText"))
                            .multilineTextAlignment(.leading)
                    }
                    if let total = item.totalWeeks, let stage = item.stage(on: Date()), stage != .finished {
                        BlockProgress(total: total, stage: stage)
                            .padding(.top, 4)
                    }
                }
                Spacer()
                trailing(isBusy: isBusy)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("BrandPrimary").opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("BrandPrimary").opacity(0.6), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isBusy)
        .accessibilityHint("Edit focus")
    }
}

/// One segment per week; done weeks filled, the test week outlined.
private struct BlockProgress: View {
    let total: Int
    let stage: TrainingMemoryItem.BlockStage

    private var current: Int {
        switch stage {
        case let .week(week, _): return week
        case let .testWeek(total): return total
        case .finished: return total
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...total, id: \.self) { week in
                RoundedRectangle(cornerRadius: 2)
                    .fill(week <= current ? Color("BrandPrimary") : Color("Border"))
                    .frame(height: 4)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Habit / avoid row

private struct MemoryRow: View {
    let item: TrainingMemoryItem
    let icon: String
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(Color("SecondaryText"))
                    .frame(width: 24)
                Text(item.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))
                    .multilineTextAlignment(.leading)
                Spacer()
                trailing(isBusy: isBusy)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Border"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isBusy)
        .accessibilityHint("Edit")
    }
}

@ViewBuilder
private func trailing(isBusy: Bool) -> some View {
    if isBusy {
        ProgressView()
            .tint(Color("BrandPrimary"))
    } else {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(Color("TertiaryText"))
    }
}

#Preview("With items") {
    NavigationStack {
        TrainingMemoryView(viewModel: TrainingMemoryViewModel(api: .preview(.sample)))
    }
}

#Preview("Empty") {
    NavigationStack {
        TrainingMemoryView(viewModel: TrainingMemoryViewModel(api: .preview(.empty)))
    }
}

#if DEBUG
extension TrainingMemory {
    static let sample = TrainingMemory(
        focus: TrainingMemoryItem(id: "f", kind: .focus, text: "Snatch", startsOn: "2026-10-19", endsOn: "2026-11-16"),
        habits: [TrainingMemoryItem(id: "h", kind: .habit, text: "Warmup + mobility every session")],
        avoid: [TrainingMemoryItem(id: "a", kind: .avoid, text: "No burpees")]
    )
}

extension TrainingMemoryAPI {
    /// Stays off the network: rewording and removals succeed locally (a new
    /// block length isn't shown).
    static func preview(_ memory: TrainingMemory) -> TrainingMemoryAPI {
        TrainingMemoryAPI(
            load: { memory },
            update: { id, text, _ in
                var item = memory.item(id: id) ?? TrainingMemoryItem(id: id, kind: .habit, text: "")
                if let text { item.text = text }
                return item
            },
            remove: { _ in true }
        )
    }
}
#endif
