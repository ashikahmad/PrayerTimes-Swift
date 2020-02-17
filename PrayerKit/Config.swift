//
//  Config.swift
//  PrayerKit
//
//  Created by Ashik uddin Ahmad on 4/28/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import Foundation
import AKPrayerTime

class Config {
    static private(set) var global = Config()

    // ================================================
    // Test Values
    // ------------------------------------------------
    // (lat: 23.810332, lng: 90.4125181)    ~~> tz: +6
    // (lat: 43.6605, lng: -79.4633)        ~~> tz: -5
    // ================================================
    var coordinate: Coordinate = .init(lat: 23.810332, lng: 90.4125181)
    var address: String? = "Dhaka"
    var gmtOffset: Float = TimeZone.current.inHours()

    var calcMethod: CalculationMethod = .karachi
    var asrMethod: AsrJuristicMethod = .hanafi
    var highLat: HigherLatutudeAdjustment = .midNight
    var midnight: MidnightMethod = .standard

    var calcDate: Date = Date()
}
