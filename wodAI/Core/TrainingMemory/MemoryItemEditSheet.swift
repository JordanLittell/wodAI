//
//  MemoryItemEditSheet.swift
//  wodAI
//
//  Corrects one item on Your training: its wording and, for a focus, the
//  block length (counted from the block's first day). The destructive button
//  ends a focus or removes a habit or avoid, after a confirmation.
//

import SwiftUI

struct MemoryItemEditSheet: View {
    let item: TrainingMemoryItem
    @ObservedObject var viewModel: TrainingMemoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var text: String
    @State private var weeks: Int
    @State private var confirmingRemoval = false
    @FocusState private var textFocused: Bool

    init(item: TrainingMemoryItem, viewModel: TrainingMemoryViewModel) {
        self.item = item
        self.viewModel = viewModel
        _text = State(initialValue: item.text)
        _weeks = State(initialValue: item.totalWeeks ?? 4)
    }

    private var isBusy: Bool { viewModel.busyId == item.id }

    private var title: String {
        switch item.kind {
        case .focus: return "Edit focus"
        case .habit: return "Edit habit"
        case .avoid: return "Edit what to leave out"
        }
    }

    private var removeLabel: String { item.kind == .focus ? "End focus" : "Remove" }

    private var removeMessage: String {
        item.kind == .focus
            ? "The coach stops building your sessions toward this focus."
            : "The coach stops keeping to this in your sessions."
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($textFocused)
                        .foregroundColor(Color("PrimaryText"))
                        .padding()
                        .background(Color("Surface2"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Border"), lineWidth: 1)
                        )
                    if text.count > TrainingMemoryItem.maxTextLength {
                        Text("\(text.count)/\(TrainingMemoryItem.maxTextLength) characters")
                            .font(.caption)
                            .foregroundColor(Color("Error"))
                    }
                }

                if item.kind == .focus {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Block length")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                        Stepper(value: $weeks, in: 1...TrainingMemoryItem.maxWeeks) {
                            Text(weeks == 1 ? "1 week" : "\(weeks) weeks")
                                .foregroundColor(Color("PrimaryText"))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color("Surface2"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Border"), lineWidth: 1)
                        )
                        Text("From the block's first week. The last week is a de-load, then a test.")
                            .font(.caption)
                            .foregroundColor(Color("TertiaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    Task {
                        if await viewModel.save(item, text: text, weeks: item.kind == .focus ? weeks : nil) { dismiss() }
                    }
                } label: {
                    Group {
                        if isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandPrimary"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isBusy)

                Button(role: .destructive) {
                    confirmingRemoval = true
                } label: {
                    Text(removeLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("Error"))
                        .frame(maxWidth: .infinity)
                }
                .disabled(isBusy)

                Spacer()
            }
            .padding()
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .confirmationDialog(removeLabel + "?", isPresented: $confirmingRemoval, titleVisibility: .visible) {
                Button(removeLabel, role: .destructive) {
                    Task {
                        if await viewModel.remove(item) { dismiss() }
                    }
                }
            } message: {
                Text(removeMessage)
            }
            .alert("Couldn't save", isPresented: $viewModel.hasActionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.actionError ?? "Please try again.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
