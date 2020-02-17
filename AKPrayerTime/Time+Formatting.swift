//
//  AKPrayerTime+Formatting.swift
//  AKPrayerTime
//
//  Created by Ashik uddin Ahmad on 12/3/18.
//  Copyright © 2018 WNeeds. All rights reserved.
//

import Foundation

public extension Time {

    func toDate(base date: Date = Date(),
                calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hours
        components.minute = minutes
        return calendar.date(from: components) ?? date
    }

    func toTime12(showSuffix: Bool = true) -> String {
        var h = hours % 12
        let m = minutes
        let a = (showSuffix ? ((hours > 12) ? " pm" : " am") : "")
        if h == 0 { h = 12 }
        return String(format: "%02d:%02d%@", h, m, a)
    }

    func toTime24() -> String {
        return String(format: "%02d:%02d", hours, minutes)
    }
}

extension Time: Comparable {
    
    public static func < (lhs: Time, rhs: Time) -> Bool {
        return lhs.duration < rhs.duration
    }

    public static func == (lhs: Time, rhs: Time) -> Bool {
        return lhs.duration == rhs.duration
    }
}

extension Time {
    func prevDayDuration() -> Double {
        return duration - 24
    }

    func nextDayDuration() -> Double {
        return duration + 24
    }
}
