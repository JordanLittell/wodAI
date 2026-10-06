//
//  DateUtility.swift
//  wodAI
//
//  Centralized date handling utilities to ensure consistent timezone conversion
//  between device timezone and UTC for GraphQL API communication
//

import Foundation

struct DateUtility {
    
    // MARK: - Shared Calendar
    
    static let deviceCalendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        cal.firstWeekday = 1 // Sunday = 1, Monday = 2
        return cal
    }()
    
    static let utcCalendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone(abbreviation: "UTC")!
        return cal
    }()
    
    // MARK: - GraphQL Date Formatting
    
    /// Formats a Date for GraphQL DateTime input, converting device timezone to UTC
    /// - Parameter date: Device timezone date
    /// - Returns: ISO8601 formatted UTC datetime string
    static func formatDateForGraphQL(_ date: Date) -> String {
        // Get start of day in device timezone
        let deviceStartOfDay = deviceCalendar.startOfDay(for: date)
        
        // Create ISO8601 formatter for UTC
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.timeZone = TimeZone(abbreviation: "UTC")
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        return iso8601Formatter.string(from: deviceStartOfDay)
    }
    
    /// Parses a GraphQL DateTime string that represents a date concept (not a moment)
    /// Since Postgres stores dates as UTC midnight, we need to interpret them as date concepts
    /// - Parameter dateTimeString: UTC datetime string from GraphQL (e.g. "2025-08-12T00:00:00Z")
    /// - Returns: Device timezone date representing the same calendar date
    static func parseDateFromGraphQL(_ dateTimeString: String?) -> Date? {
        guard let dateTimeString = dateTimeString else { return nil }
        
        // Parse the UTC datetime
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var utcDate: Date?
        
        // Try with fractional seconds first
        if let parsed = iso8601Formatter.date(from: dateTimeString) {
            utcDate = parsed
        } else {
            // Try without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let parsed = iso8601Formatter.date(from: dateTimeString) {
                utcDate = parsed
            } else {
                // Try date-only format
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                utcDate = dateFormatter.date(from: dateTimeString)
            }
        }
        
        guard let parsedUTCDate = utcDate else {
            print("❌ DateUtility: Failed to parse date from GraphQL: \(dateTimeString)")
            return nil
        }
        
        // Extract the calendar date components from UTC
        let utcCalendar = Calendar(identifier: .gregorian)
        var utcCalendarCopy = utcCalendar
        utcCalendarCopy.timeZone = TimeZone(abbreviation: "UTC")!
        
        let components = utcCalendarCopy.dateComponents([.year, .month, .day], from: parsedUTCDate)
        
        // Create the same calendar date in device timezone
        guard let deviceDate = deviceCalendar.date(from: components) else {
            print("❌ DateUtility: Failed to create device date from components: \(components)")
            return nil
        }
        
        let deviceStartOfDay = deviceCalendar.startOfDay(for: deviceDate)
        
        #if DEBUG
        let debugFormatter = DateFormatter()
        debugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        debugFormatter.timeZone = TimeZone.current
        print("🔄 Parsed GraphQL: '\(dateTimeString)' -> \(debugFormatter.string(from: deviceStartOfDay))")
        #endif
        
        return deviceStartOfDay
    }
    

    
    // MARK: - Week Calculation Helpers
    
    /// Generates all 7 days for a week containing the given date
    /// - Parameter referenceDate: Any date within the desired week
    /// - Returns: Array of 7 dates representing Sunday through Saturday
    static func generateWeekDays(containing referenceDate: Date) -> [Date] {
        guard let weekInterval = deviceCalendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            print("❌ DateUtility: Could not calculate week interval for: \(referenceDate)")
            return []
        }
        
        let startOfWeek = weekInterval.start
        
        let weekDays = (0..<7).compactMap { dayOffset in
            return deviceCalendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
        
        #if DEBUG
        if let first = weekDays.first, let last = weekDays.last {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM d"
            formatter.timeZone = TimeZone.current
            print("📅 DateUtility: Generated week: \(formatter.string(from: first)) - \(formatter.string(from: last))")
        }
        #endif
        
        return weekDays
    }
    
    // MARK: - Date Comparison Helpers
    
    /// Checks if two dates are the same day (ignoring time)
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: True if both dates are on the same calendar day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return deviceCalendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Checks if a date is today
    /// - Parameter date: Date to check
    /// - Returns: True if the date is today
    static func isToday(_ date: Date) -> Bool {
        return deviceCalendar.isDateInToday(date)
    }
    
    /// Gets the start of day for a given date in device timezone
    /// - Parameter date: Input date
    /// - Returns: Start of day for the given date in device timezone
    static func startOfDay(for date: Date) -> Date {
        return deviceCalendar.startOfDay(for: date)
    }
    
    // MARK: - Display Formatters
    
    /// Standard date formatter for user-facing display
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    /// Short date formatter for compact display
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    /// Day name formatter for week views
    static let dayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Debug Helpers
    
    /// Logs timezone information for debugging
    static func logTimezoneInfo() {
        print("🕐 DateUtility Timezone Info:")
        print("  Device timezone: \(TimeZone.current.identifier)")
        print("  Device GMT offset: \(TimeZone.current.secondsFromGMT() / 3600) hours")
        print("  UTC time: \(ISO8601DateFormatter().string(from: Date()))")
        print("  Device time: \(displayDateFormatter.string(from: Date()))")
    }
    
    /// Debug helper to verify week generation
    static func debugWeekGeneration(for date: Date) {
        guard let weekInterval = deviceCalendar.dateInterval(of: .weekOfYear, for: date) else {
            print("❌ Could not calculate week interval for: \(date)")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d, yyyy"
        formatter.timeZone = TimeZone.current
        
        print("📌 Week Debug for: \(formatter.string(from: date))")
        print("  Week interval start: \(formatter.string(from: weekInterval.start))")
        print("  Week interval end: \(formatter.string(from: weekInterval.end)) (exclusive)")
        
        let actualEndDate = deviceCalendar.date(byAdding: .day, value: -1, to: weekInterval.end)!
        print("  Actual last day: \(formatter.string(from: actualEndDate))")
        
        let weekDays = generateWeekDays(containing: date)
        print("  Generated week days:")
        for (index, day) in weekDays.enumerated() {
            let dayName = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][index]
            print("    \(dayName): \(formatter.string(from: day))")
        }
    }
}
