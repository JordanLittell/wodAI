//
//  DateParser.swift
//  wodAI
//
//  Created by Jordan Littell on 7/27/25.
//
import WodAiAPI
import SwiftUI

struct DateParser {
    public func parseDate(_ dateTime: WodAiAPI.DateTime?) -> Date? {
        guard let dateTime = dateTime else { return nil }
        
        // DateTime is likely a typealias for String in the generated code
        let dateString = String(describing: dateTime)
        
        // Try multiple date formats
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

