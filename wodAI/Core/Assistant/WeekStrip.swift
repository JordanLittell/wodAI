//
//  WeekStrip.swift
//  wodAI
//

import SwiftUI

/// The Assistant page's week: one column per day with its weekday initial and
/// date. The selected day is filled, today is drawn in the brand color, and a
/// dot marks days that have a session. Swiping it sideways moves a week.
struct WeekStrip: View {
    let week: AssistantWeek
    let selectedDay: Date
    /// Where a new week slides in from: trailing when moving forward.
    let slideEdge: Edge
    let hasSession: (Date) -> Bool
    let onSelect: (Date) -> Void
    /// Called with +1 for the next week, -1 for the previous one.
    let onChangeWeek: (Int) -> Void

    var body: some View {
        ZStack {
            days
                // A new identity per week so changing weeks slides the row.
                .id(week.first)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge),
                    removal: .move(edge: slideEdge == .trailing ? .leading : .trailing)
                ))
        }
        .clipped()
        .contentShape(Rectangle())
        // High priority so a sideways drag that starts on a day changes the
        // week rather than being lost to the day's button; a tap still selects.
        .highPriorityGesture(weekSwipe)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("weekStrip")
        .accessibilityAction(named: "Previous week") { onChangeWeek(-1) }
        .accessibilityAction(named: "Next week") { onChangeWeek(1) }
    }

    private var days: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.days.enumerated()), id: \.element) { index, day in
                Button {
                    onSelect(day)
                } label: {
                    column(day)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("day-\(index)")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    /// Swipe left for the next week, right for the previous one, when the
    /// drag is mostly sideways and long enough to be deliberate.
    private var weekSwipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > abs(value.translation.height), abs(dx) > 40 else { return }
                onChangeWeek(dx < 0 ? 1 : -1)
            }
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
