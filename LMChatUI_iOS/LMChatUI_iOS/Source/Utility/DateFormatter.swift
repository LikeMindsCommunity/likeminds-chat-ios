//
//  DateFormatter.swift
//  LikeMindsChatUI
//
//  Created by Devansh Mohata on 16/05/24.
//

import Foundation

public final class LMChatDateUtility {
    
    static func formatDate(_ epochTime: Double) -> String {
        // Check if the epoch time is in seconds or milliseconds
        let isMilliseconds = epochTime > 1_000_000_000_000
        let interval: TimeInterval = isMilliseconds ? epochTime / 1000.0 : epochTime
        let date = Date(timeIntervalSince1970: interval)
        
        // Get the current date and calendar components
        let calendar = Calendar.current
        
        // Check if the date is today or yesterday
        if calendar.isDateInToday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            // Format the date as DD/MM/YY
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yy"
            return dateFormatter.string(from: date)
        }
    }
    
    /// Specific Function to Convert `Double` aka `TimeInterval` to Human Readable Formatted Time String for Post Widget use case!
    public static func timeIntervalPostWidget(timeIntervalInMilliSeconds time: Int) -> String {
        if Double(time / 1000) == Date().timeIntervalSince1970 {
            return "Just Now"
        }
        
        if let time = timeIntervalToDate(Double(time / 1000)) {
            return time
        }
        
        return ""
    }
    
    
    /// Generic Function to Convert `Double` aka `TimeInterval` to Human Readable Formatted Time String
    public static func timeIntervalToDate(_ time: Double) -> String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .short
        return formatter.string(for: Date(timeIntervalSince1970: time))
    }
    
    public static func formatDate(_ date: Date, toFormat format: String = "dd-MM-yyyy HH:mm") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    public static func isEpochTimeInSeconds(_ epochTime: Int) -> Bool {
        let epochTimeString = String(epochTime)
        let numDigits = epochTimeString.count
        
        /// Epoch time values with 10 or fewer digits are assumed to be in seconds
        /// Epoch time values with more than 10 digits are assumed to be in milliseconds
        return numDigits <= 10
    }
}
