//
//  ActivityCards.swift
//  wodAI
//
//  The Stats feed's rows: a dated divider for each day, a HIIT card tinted by
//  the athlete's RPE (heart-rate curve on top when one was recorded), and a
//  strength card with the rep scheme and how the load climbed.
//

import SwiftUI

// MARK: - Day divider

struct ActivityDayDivider: View {
    let day: Date
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(ActivityFeed.dayLabel(day))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color("PrimaryText"))
            Rectangle()
                .fill(Color("Border"))
                .frame(height: 1)
            Text(count == 1 ? "1 workout" : "\(count) workouts")
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - HIIT

struct CompletedHiitCard: View {
    let entry: CompletedHiitEntry

    private var band: RPEBand? { RPEBand(rpe: entry.perceivedEffort) }
    private var accent: Color? { band.map { Color($0.colorName) } }
    private var hasHeartRate: Bool { entry.heartRate.count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasHeartRate {
                HStack(alignment: .center, spacing: 12) {
                    HeartRateSparkline(points: entry.heartRate, showsAxes: false)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                    heartRateStats
                    rpeBadge
                }
                titleRow
            } else {
                HStack(alignment: .top) {
                    titleRow
                    Spacer()
                    rpeBadge
                }
            }

            if !entry.displayText.isEmpty {
                Text(entry.displayText)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(Color("PrimaryText"))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            footer
        }
        .padding()
        .padding(.leading, accent == nil ? 0 : 4)
        .background(
            ZStack(alignment: .leading) {
                Color("Surface")
                if let accent {
                    accent.opacity(0.10)
                    accent.frame(width: 4)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent?.opacity(0.35) ?? Color("Border"), lineWidth: 1)
        )
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            if let format = entry.format, !format.isEmpty {
                Text(format)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("BrandPrimary"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color("BrandPrimary").opacity(0.12))
                    .cornerRadius(6)
            }
            Text(entry.stimulus)
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var heartRateStats: some View {
        if let avg = entry.avgHeartRate {
            VStack(alignment: .trailing, spacing: 2) {
                Label("\(avg)", systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundColor(Color("PrimaryText"))
                    .labelStyle(TintedIconLabelStyle(tint: .red))
                Text(entry.maxHeartRate.map { "avg · max \($0)" } ?? "avg bpm")
                    .font(.caption2)
                    .foregroundColor(Color("SecondaryText"))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.maxHeartRate.map { "Average heart rate \(avg), max \($0)" } ?? "Average heart rate \(avg)")
        }
    }

    @ViewBuilder
    private var rpeBadge: some View {
        if let band, let accent, let rpe = entry.perceivedEffort {
            VStack(spacing: 0) {
                Text("RPE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                Text("\(rpe)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                Text(band.label)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(accent)
            .fixedSize()
            .frame(minWidth: 44)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(accent.opacity(0.16))
            .cornerRadius(10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Effort \(rpe) of 10, \(band.label)")
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Label(entry.completedAt.formatted(date: .omitted, time: .shortened), systemImage: "clock")
            if let load = entry.trainingLoad {
                Label("Load \(Int(load.rounded()))", systemImage: "flame.fill")
            }
            if !hasHeartRate, let bpm = entry.avgHeartRate {
                Label("\(bpm) avg bpm", systemImage: "heart.fill")
            }
        }
        .font(.caption)
        .foregroundColor(Color("SecondaryText"))
    }
}

private struct TintedIconLabelStyle: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundColor(tint).font(.caption)
            configuration.title
        }
    }
}

// MARK: - Strength

struct CompletedStrengthCard: View {
    let entry: CompletedStrengthEntry
    @AppStorage("weightUnit") private var unit: WeightUnit = .lb

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.subheadline)
                    .foregroundColor(Color("BrandPrimary"))
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                    .lineLimit(2)
                Spacer()
                Text(entry.completedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }

            ForEach(entry.lifts, id: \.exercise) { lift in
                liftRow(lift)
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }

    private func liftRow(_ lift: CompletedStrengthEntry.Lift) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                // The piece's title already names a single lift.
                if entry.lifts.count > 1 || lift.exercise != entry.title {
                    Text(lift.exercise)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("PrimaryText"))
                }
                if let scheme = StrengthText.scheme(lift.prescribedReps) {
                    Text(scheme)
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            if let progression = StrengthText.progression(lift.loggedWeights, unit: unit) {
                Text(progression)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundColor(Color("PrimaryText"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
