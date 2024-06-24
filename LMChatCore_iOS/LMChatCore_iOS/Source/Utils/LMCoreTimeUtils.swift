//
//  TimeUtils.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/04/24.
//

import Foundation

class LMCoreTimeUtils {
    
    static func generateCreateAtDate(miliseconds: Double, format: String = "dd MMM yyyy") -> String {
        return Date(milliseconds: miliseconds).getDateString(withFormat: format)
    }
    
    static func timestampConverted(withEpoch epoch: Int, withOnlyTime isOnlyTime: Bool = true) -> String? {
        guard epoch > .zero else { return nil }
        var epochTime = Double(epoch)
        
        if epochTime > Date().timeIntervalSince1970 {
            epochTime = epochTime / 1000
        }
        
        let date = Date(timeIntervalSince1970: epochTime)
        let dateFormatter = DateFormatter()
        
        if isOnlyTime {
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        } else {
            if Calendar.current.isDateInToday(date) {
                dateFormatter.dateFormat = "HH:mm"
                //            dateFormatter.dateFormat = "hh:mm a"
                //            dateFormatter.amSymbol = "AM"
                //            dateFormatter.pmSymbol = "PM"
                return dateFormatter.string(from: date)
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                dateFormatter.dateFormat = "dd/MM/yy"
                return dateFormatter.string(from: date)
            }
        }
    }
}
