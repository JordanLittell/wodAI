//
//  ExerciseSummaryHeader.swift
//  wodAI
//
//  Top of a strength block: a full-width how-to video (with the exercise's
//  target muscles along its bottom edge), a subtle divider, then the
//  athlete's working 1RM.
//

import SwiftUI

struct ExerciseSummaryHeader: View {
    let exercise: String
    /// Display-ready target muscles; the chips are omitted when empty.
    let muscleGroups: [String]
    /// How-to video; the placeholder shows when nil or unplayable.
    let videoURL: URL?
    /// Pounds. Nil when not entered yet.
    let oneRepMax: Double?
    /// False for bodyweight work, where a 1RM doesn't apply.
    let tracksOneRepMax: Bool
    let unit: WeightUnit
    let onEditOneRepMax: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(exercise)
                .font(.subheadline)
                .foregroundColor(Color.primary)
            media
            
            Divider()
            
            if !muscleGroups.isEmpty {
                muscleChips
                    .padding(12)
            }

            if tracksOneRepMax {
                oneRepMaxTile
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - How-to media

    private var videoSource: ExerciseVideoSource? {
        videoURL.flatMap(ExerciseVideoSource.init(url:))
    }

    /// Full row width at 16:9, the shape of a phone-shot demo, so the
    /// movement is big enough to actually watch.
    @ViewBuilder
    private var media: some View {
        if let videoSource {
            ExerciseVideoPlayer(source: videoSource)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("\(exercise) how-to video")
        } else {
            mediaPlaceholder
        }
    }

    /// Shown for an exercise with no video yet.
    private var mediaPlaceholder: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("Surface"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("Border"), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                )

            VStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color("TertiaryText"))
                Text("How-to video coming soon")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// What the exercise works, as small chips along the player's bottom edge.
    /// Muscles that don't fit on one line are dropped from the end rather than
    /// wrapped, so the chips never climb into the play icon.
    private var muscleChips: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(Array(stride(from: muscleGroups.count, to: 0, by: -1)), id: \.self) { count in
                HStack(spacing: 6) {
                    ForEach(muscleGroups.prefix(count), id: \.self) { muscle in
                        Text(muscle)
                            .font(.caption.weight(.medium))
                            .foregroundColor(Color("PrimaryText"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color("Background")))
                            .overlay(Capsule().stroke(Color("Border"), lineWidth: 1))
                            .fixedSize()
                    }
                }
            }
        }
    }

    private var accessibilityDescription: String {
        let video = "\(exercise) how-to video, coming soon"
        guard !muscleGroups.isEmpty else { return video }
        return "\(video). Works \(muscleGroups.joined(separator: ", "))"
    }

    // MARK: - Working 1RM

    /// Tappable either way: "Add" when missing, the value (to edit) when set.
    private var oneRepMaxTile: some View {
        Button(action: onEditOneRepMax) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Working 1RM")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    if let oneRepMax {
                        Text("\(unit.format(oneRepMax)) \(unit.rawValue)")
                            .font(.headline.monospacedDigit())
                            .foregroundColor(Color("PrimaryText"))
                    } else {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(Color("BrandPrimary"))
                    }
                }
                Spacer()
                // Full width now, so there's room to say it's editable.
                if oneRepMax != nil {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .padding(12)
            .background(Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("BrandPrimary").opacity(0.5), lineWidth: 1)
            )
        }
        // Borderless so it doesn't claim taps for the whole List row.
        .buttonStyle(.borderless)
        .accessibilityLabel(oneRepMax.map { "Working 1RM, \(unit.format($0)) \(unit.spokenName)" } ?? "Add working 1RM")
        .accessibilityHint("Opens the keypad")
    }
}

#Preview {
    List {
        Section {
            ExerciseSummaryHeader(
                exercise: "Back Squat", muscleGroups: ["Quads", "Glutes", "Adductors", "Lower Back"],
                videoURL: nil,
                oneRepMax: 275, tracksOneRepMax: true, unit: .lb, onEditOneRepMax: {}
            )
        }
        Section {
            ExerciseSummaryHeader(
                exercise: "Pull-up", muscleGroups: ["Lats", "Biceps"], videoURL: nil,
                oneRepMax: nil, tracksOneRepMax: false, unit: .lb, onEditOneRepMax: {}
            )
        }
    }
}
