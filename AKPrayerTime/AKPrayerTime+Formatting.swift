//
//  AKPrayerTime+Formatting.swift
//  AKPrayerTime
//
//  Created by Ashik uddin Ahmad on 12/3/18.
//  Copyright © 2018 WNeeds. All rights reserved.
//

import Foundation

public extension AKPrayerTime.Time {
    public func toDate(base date: Date = Date(),
                       calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hours
        components.minute = minutes
        return calendar.date(from: components) ?? date
    }

    public func toTime12(showSuffix: Bool = true) -> String {
        return String(format: "%02d:%02d%@",
                      (hours % 12),
                      minutes,
                      (showSuffix ? ((hours > 12) ? " pm" : " am") : "")  )
    }

    public func toTime24() -> String {
        return String(format: "%02d:%02d", hours, minutes)
    }
}
