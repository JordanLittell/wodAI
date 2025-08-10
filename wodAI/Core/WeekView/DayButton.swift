//
//  DayButton.swift
//  wodAI
//
//  Created by Jordan Littell on 8/10/25.
//
import SwiftUI
import WodAiAPI

// MARK: - Day Button Status
enum DayButtonStatus {
    case loading
    case noWorkout
    case workoutScheduled(WorkoutStatus)
    
    var hasIndicator: Bool {
        switch self {
        case .loading: return true
        case .workoutScheduled(let status):
            switch status {
                case .generated: return true
                case .completed: return true
                case .pending: return false
                case .failed: return false
                case .generating: return false
                default: return false
            }
        case .noWorkout: return false
        }
    }
    
    var indicatorColor: Color {
        switch self {
        case .loading:
            return Color("BrandPrimary") // Blue while loading
        case .noWorkout:
            return Color.gray // Gray when no workout scheduled
        case .workoutScheduled(let status):
            switch status {
            case .pending, .generated:
                return Color("BrandPrimary") // Blue when workout is scheduled
            case .completed:
                return Color("Success") // Green when workout completed
            case .failed:
                return Color("Warning") // Red when workout generation failed
            case .generating:
                return Color("BrandPrimary") // Blue (will pulse) when generating
            default:
                return Color("BrandPrimary")
            }
        }
    }
}

// MARK: - Enhanced Day Button Component
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isDragging: Bool
    let status: DayButtonStatus
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private var dayAbbreviation: String {
        let fullDay = dayFormatter.string(from: date)
        switch fullDay {
        case "Sun": return "Sun"
        case "Mon": return "M"
        case "Tue": return "T"
        case "Wed": return "W"
        case "Thu": return "Th"
        case "Fri": return "F"
        case "Sat": return "Sat"
        default: return String(fullDay.prefix(1))
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(dayAbbreviation)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : Color("SecondaryText"))
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                
                // Status indicator - always show
                if (status.hasIndicator) {
                    Circle()
                        .fill(isSelected ? Color.white : status.indicatorColor)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 44, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("BrandPrimary") : Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday && !isSelected ? Color("BrandPrimary") : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isDragging ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
