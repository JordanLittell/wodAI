//
//  CreateSessionSheet.swift
//  wodAI
//
//  "Create with AI": the athlete describes the session they want and it's
//  generated onto the day being shown. What they write outranks their usual
//  profile, equipment, and fatigue on the server.
//

import SwiftUI

struct CreateSessionSheet: View {
    /// The text being written; kept by the owner so a retry starts from it.
    @Binding var request: String
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    /// Matches the server's limit.
    static let maxLength = 1000

    private static let examples = [
        "Bodyweight, in my room, 20 minutes",
        "Upper body pump with dumbbells",
        "Easy recovery flush",
    ]

    private var trimmed: String { request.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Describe the session you want…", text: $request, axis: .vertical)
                    .lineLimit(3...8)
                    .focused($isFocused)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("Surface")))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Border"), lineWidth: 1))
                    .onChange(of: request) { _, newValue in
                        if newValue.count > Self.maxLength {
                            request = String(newValue.prefix(Self.maxLength))
                        }
                    }

                HStack {
                    Text("Your request overrides your usual equipment and recovery for this session.")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    Spacer(minLength: 8)
                    // Only worth showing near the limit.
                    if request.count > Self.maxLength - 200 {
                        Text("\(request.count)/\(Self.maxLength)")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(Color("SecondaryText"))
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Self.examples, id: \.self) { example in
                            Button(example) { request = example }
                                .font(.subheadline)
                                .foregroundColor(Color("PrimaryText"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color("Surface")))
                                .overlay(Capsule().stroke(Color("Border"), lineWidth: 1))
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("Create with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let text = trimmed
                        dismiss()
                        onCreate(text)
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    @Previewable @State var request = ""
    Color.clear.sheet(isPresented: .constant(true)) {
        CreateSessionSheet(request: $request) { _ in }
    }
}
