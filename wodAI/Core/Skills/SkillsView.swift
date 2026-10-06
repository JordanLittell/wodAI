//
//  SkillsView.swift
//  wodAI
//
//  Skills: a searchable, alphabetical list of movements. The user toggles off
//  movements they can't perform; those move to an "Excluded" section and are
//  filtered out of generated workouts.
//

import SwiftUI

struct SkillsView: View {
    @StateObject private var viewModel = SkillsViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.movements.isEmpty {
                ProgressView()
                    .tint(Color("BrandPrimary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error, viewModel.movements.isEmpty {
                SkillsErrorCard(error: error) { viewModel.load() }
            } else {
                content
            }
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle("Skills")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.movements.isEmpty { viewModel.load() }
        }
        .alert("Couldn't update movement", isPresented: $viewModel.hasToggleError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.toggleErrorMessage ?? "Please try again.")
        }
    }

    private var content: some View {
        VStack(spacing: 16) {
            searchBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    section(
                        title: "Movements",
                        subtitle: "Tap a movement you can't perform to remove it from your workouts.",
                        items: viewModel.available,
                        emptyText: viewModel.searchText.isEmpty ? nil : "No movements match \"\(viewModel.searchText)\"."
                    )

                    if !viewModel.excluded.isEmpty {
                        section(
                            title: "Excluded",
                            subtitle: "These won't appear in generated workouts. Tap to re-enable.",
                            items: viewModel.excluded,
                            emptyText: nil
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("PlaceholderColor"))
            TextField("Search movements to exclude", text: $viewModel.searchText)
                .foregroundColor(Color("PrimaryText"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .focused($searchFocused)
            // Always present (hidden when empty) so the HStack's child count
            // never changes — inserting/removing a sibling here would drop the
            // TextField's first responder and dismiss the keyboard mid-typing.
            Button {
                viewModel.searchText = ""
                searchFocused = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("TertiaryText"))
            }
            .opacity(viewModel.searchText.isEmpty ? 0 : 1)
            .allowsHitTesting(!viewModel.searchText.isEmpty)
        }
        .padding()
        .background(Color("Surface2"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("Border"), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Section

    @ViewBuilder
    private func section(title: String, subtitle: String, items: [Movement], emptyText: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("SecondaryText"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
            }

            if items.isEmpty, let emptyText {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundColor(Color("TertiaryText"))
                    .padding(.vertical, 8)
            } else {
                ForEach(items) { movement in
                    MovementRow(
                        movement: movement,
                        isToggling: viewModel.togglingIds.contains(movement.id)
                    ) {
                        viewModel.setExcluded(movement, excluded: !movement.excluded)
                    }
                }
            }
        }
    }
}

// MARK: - Row

private struct MovementRow: View {
    let movement: Movement
    let isToggling: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(movement.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(movement.excluded ? Color("SecondaryText") : Color("PrimaryText"))
                        .strikethrough(movement.excluded, color: Color("SecondaryText"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if !movement.muscleGroupsDisplay.isEmpty {
                        Text(movement.muscleGroupsDisplay)
                            .font(.caption)
                            .foregroundColor(Color("TertiaryText"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isToggling {
                    ProgressView()
                        .tint(Color("BrandPrimary"))
                } else {
                    Image(systemName: movement.excluded ? "arrow.uturn.left.circle.fill" : "minus.circle")
                        .font(.title3)
                        .foregroundColor(movement.excluded ? Color("BrandPrimary") : Color("TertiaryText"))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(movement.excluded ? Color("Surface2") : Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Border"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isToggling)
    }
}

// MARK: - Error card

private struct SkillsErrorCard: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color("Warning"))
            Text("Unable to load movements")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .foregroundColor(Color("BrandPrimary"))
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        SkillsView()
    }
}
