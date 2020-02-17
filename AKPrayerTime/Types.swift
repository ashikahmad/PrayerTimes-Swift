//
//  Types.swift
//  AKPrayerTime
//
//  Created by Ashik uddin Ahmad on 5/7/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import Foundation

// -----------------------------------------------------------
// MARK: Convenient Types
// -----------------------------------------------------------

public enum PrayerName : String {
    case imsak
    case fajr
    case sunrise
    case dhuhr
    case asr
    case sunset
    case maghrib
    case isha
    case midnight
    case qiyam

    static let all: [PrayerName] = [.imsak, .fajr, .sunrise, .dhuhr, .asr, .sunset, .maghrib, .isha, .midnight, .qiyam]

    public func toString()->String {
        return self.rawValue.capitalized
    }
}

/**
 `Time` wraps double time into a formal namespace
 along with basic functionalities
 */
public struct Time {
    public let duration: Double

    public init(hours: Int, minutes: Int) {
        let fixedHours = Time.fixedHours(Double(hours))
        self.duration = fixedHours + Double(minutes) / 60.0
    }

    public init(duration: Double) {
        var ttime = duration + 0.5 / 60.0 // add 0.5 minutes to round
        ttime = Time.fixedHours(ttime)
        self.duration = ttime
    }

    private static func fixedHours(_ hours: Double) -> Double {
        return DMath.wrap(hours, min: 0, max: 24)
    }

    public var hours: Int {
        return Int(floor(duration))
    }

    public var minutes: Int {
        return Int(floor((duration - Double(hours)) * 60.0))
    }
}

// MARK: -
public struct Coordinate {
    public var latitude: Double
    public var longitude: Double
    public var elevation: Double

    public init(lat: Double, lng: Double, elv: Double = 0) {
        latitude = lat
        longitude = lng
        elevation = elv
    }
}
