//
//  WeekStrip.swift
//  wodAI
//

import SwiftUI

/// The Assistant page's week: one column per day with its weekday initial and
/// date. The selected day is filled, today is drawn in the brand color, and a
/// dot marks days that have a session.
struct WeekStrip: View {
    let week: AssistantWeek
    let selectedDay: Date
    let hasSession: (Date) -> Bool
    let onSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(week.days, id: \.self) { day in
                Button {
                    onSelect(day)
                } label: {
                    column(day)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func column(_ day: Date) -> some View {
        let isSelected = day == selectedDay
        let isToday = day == week.today

        return VStack(spacing: 4) {
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(isToday ? Color.brandPrimary : Color("SecondaryText"))

            Text(day.formatted(.dateTime.day()))
                .font(.subheadline.monospacedDigit())
                .fontWeight(isSelected || isToday ? .bold : .regular)
                .foregroundColor(isSelected ? .white : isToday ? Color.brandPrimary : Color("PrimaryText"))
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle().fill(Color.brandPrimary)
                    } else if isToday {
                        Circle().stroke(Color.brandPrimary, lineWidth: 1.5)
                    }
                }

            Circle()
                .fill(hasSession(day) ? Color("SecondaryText") : .clear)
                .frame(width: 5, height: 5)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(day, isToday: isToday))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func accessibilityLabel(_ day: Date, isToday: Bool) -> String {
        var label = day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if isToday { label += ", today" }
        if hasSession(day) { label += ", workout scheduled" }
        return label
    }
}
