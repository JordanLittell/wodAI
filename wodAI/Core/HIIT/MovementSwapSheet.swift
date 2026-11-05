//
//  MovementSwapSheet.swift
//  wodAI
//
//  The list a tap on a movement's name opens: the server's suggestions for the
//  line (hiitSwapOptions, already converted, so each reads as the line will)
//  on top, then every other movement. Typing filters both by name. Movements
//  the athlete excludes are never offered. The server converts the line for
//  whatever is picked (21 Cal Air Bike to 300m Run), so any pick saves a
//  valid line.
//

import SwiftUI
import WodAiAPI

/// A movement the athlete can swap in.
struct SwapCandidate: Identifiable, Hashable {
    let id: Int
    let name: String
}

struct MovementSwapSheet: View {
    let line: HIITLine
    /// The server's suggestions for this line, best first; may be empty.
    var suggestions: [SwapOption] = []
    /// Whether the line sits under a 21-15-9 style header (reps left off).
    var repScheme: Bool = false
    let onPickSuggestion: (SwapOption) -> Void
    let onPick: (SwapCandidate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var movements: [SwapCandidate] = []
    @State private var search = ""
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            List {
                if !suggestedMatches.isEmpty {
                    Section("Suggested") {
                        ForEach(suggestedMatches) { suggestionRow($0) }
                    }
                }
                Section(query.isEmpty ? "All movements" : "Movements") {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if let loadError {
                        Text(loadError).foregroundColor(Color("SecondaryText"))
                    } else if showsNoResults {
                        Text("No movements match \"\(query)\"")
                            .foregroundColor(Color("SecondaryText"))
                    } else {
                        ForEach(movementMatches) { candidateRow($0) }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search movements")
            .autocorrectionDisabled()
            .navigationTitle("Swap \(line.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await load() }
    }

    private var query: String { search.trimmingCharacters(in: .whitespaces) }

    private func matchesQuery(_ name: String) -> Bool {
        query.isEmpty || name.localizedCaseInsensitiveContains(query)
    }

    private var suggestedMatches: [SwapOption] {
        suggestions.filter { $0.id != line.exerciseId && matchesQuery($0.preview.name) }
    }

    /// Every movement but the one being replaced and the suggestions, by name.
    private var movementMatches: [SwapCandidate] {
        let suggested = Set(suggestions.map(\.id))
        return movements
            .filter { $0.id != line.exerciseId && !suggested.contains($0.id) && matchesQuery($0.name) }
            .sorted { $0.name < $1.name }
    }

    private var showsNoResults: Bool {
        !query.isEmpty && suggestedMatches.isEmpty && movementMatches.isEmpty
    }

    private func suggestionRow(_ option: SwapOption) -> some View {
        Button {
            onPickSuggestion(option)
            dismiss()
        } label: {
            Text(option.label(repScheme: repScheme))
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
    }

    private func candidateRow(_ candidate: SwapCandidate) -> some View {
        Button {
            onPick(candidate)
            dismiss()
        } label: {
            Text(candidate.name)
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
    }

    @MainActor
    private func load() async {
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                Network.shared.client.fetch(
                    query: MovementsQuery(search: .none),
                    cachePolicy: .fetchIgnoringCacheCompletely
                ) { continuation.resume(with: $0) }
            }
            movements = (result.data?.movements ?? [])
                .filter { !$0.excluded }
                .map { SwapCandidate(id: $0.id, name: $0.name) }
            if movements.isEmpty { loadError = "Couldn't load movements." }
        } catch {
            loadError = "Couldn't load movements. Check your connection."
        }
        isLoading = false
    }
}
