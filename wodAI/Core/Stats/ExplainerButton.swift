//
//  ExplainerButton.swift
//  wodAI
//
//  A small info button that opens a sheet saying, in plain words, how a card's
//  numbers are worked out: what is measured, what is estimated, and what the
//  number can't tell you.
//

import SwiftUI

struct Explainer: Identifiable, Equatable {
    let title: String
    /// Paragraphs, shown in order.
    let paragraphs: [String]
    var id: String { title }

    static let recovery = Explainer(
        title: "How we work out your training load",
        paragraphs: [
            "Every workout you do gets a training load: how long it lasted times how hard it was. For a WOD, how hard comes from your heart rate when you wore a monitor, otherwise from the effort you rated. For strength, it comes from the RPE you logged on your sets. A workout with neither isn't counted.",
            "We compare your last 7 days with your last 28. Above usual means you've done more than you're used to lately; below usual means less.",
            "This only compares your training with your own usual. It doesn't know how you slept, how stressed you are or how sore you feel, and it isn't a measure of injury risk. It needs about two weeks of rated workouts before it says much.",
        ]
    )

    static let readiness = Explainer(
        title: "How we work out recovery",
        paragraphs: [
            "Each exercise works some body regions more than others. For every workout, we estimate how much it loaded each region from the reps, the weight compared with your best lifts, and how hard you rated it. That load then wears off over one to three days, depending on the region.",
            "Ready to train is when a region drops under 30, the point where your plan will load it normally again. Fully recovered is when nothing from your recent workouts is left in it.",
            "Your plan uses the same numbers: a region above 60 is left alone and one from 30 to 60 is only worked lightly.",
            "These are estimates, not measurements. We can't see soreness, so if a region feels worse or better than this says, trust how you feel.",
        ]
    )
}

struct ExplainerButton: View {
    let explainer: Explainer
    @State private var shown: Explainer?

    var body: some View {
        Button {
            shown = explainer
        } label: {
            Image(systemName: "info.circle")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(explainer.title)
        .sheet(item: $shown) { explainer in
            ExplainerSheet(explainer: explainer)
                .presentationDetents([.medium, .large])
        }
    }
}

struct ExplainerSheet: View {
    let explainer: Explainer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(explainer.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.body)
                            .foregroundColor(Color("PrimaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle(explainer.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExplainerSheet(explainer: .recovery)
}
