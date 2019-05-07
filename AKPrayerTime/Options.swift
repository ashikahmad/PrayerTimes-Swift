//
//  Options.swift
//  AKPrayerTime
//
//  Created by Ashik uddin Ahmad on 5/7/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import Foundation

// -----------------------------------------------------------
// MARK: - Calculation Options
// -----------------------------------------------------------

public enum CalculationMethod {

    /// Muslim World League
    case mwl

    /// Islamic Society of North America
    case isna

    /// Egyptian General Authority of Survey
    case egypt

    /// Umm al-Qura University, Makkah
    case makkah

    /// University of Islamic Science, Karachi
    case karachi

    /// Institute of Geophysics, University of Tehran
    case tehran

    /// Shia Ithna Ashari, Leva Research Institute, Qum
    case jafari

    /// Custom, these can be changed as user sets.
    case custom

    var params: AKPrayerTime.MethodParams {
        switch self {
        case .mwl: return AKPrayerTime.MethodParams(
            fajrAngle: 18,
            maghrib: .minutes(0),
            isha: .angles(17),
            midnight: .standard)

        case .isna: return AKPrayerTime.MethodParams(
            fajrAngle: 15,
            maghrib: .minutes(0),
            isha: .angles(15),
            midnight: .standard)

        case .egypt: return AKPrayerTime.MethodParams(
            fajrAngle: 19.5,
            maghrib: .minutes(0),
            isha: .angles(17.5),
            midnight: .standard)

        // fajrAngle was 19 degrees before 1430 hijri
        case .makkah: return AKPrayerTime.MethodParams(
            fajrAngle: 18.5,
            maghrib: .minutes(0),
            isha: .minutes(90),
            midnight: .standard)

        case .karachi: return AKPrayerTime.MethodParams(
            fajrAngle: 18,
            maghrib: .minutes(0),
            isha: .angles(18),
            midnight: .standard)

        case .tehran: return AKPrayerTime.MethodParams(
            fajrAngle: 17.7,
            maghrib: .angles(4.5),
            isha: .angles(14),
            midnight: .jafari)

        case .jafari: return AKPrayerTime.MethodParams(
            fajrAngle: 16,
            maghrib: .angles(4),
            isha: .angles(14),
            midnight: .jafari)

        case .custom: return AKPrayerTime.MethodParams(
            fajrAngle: 18,
            maghrib: .minutes(0),
            isha: .angles(17),
            midnight: .standard)
        }
    }
}


public enum AsrJuristicMethod: Int {

    /// Shafi'i, Maliki, Ja'fari, and Hanbali
    /// Shadow coefficient is 1
    case shafii = 1

    /// Hanafi
    /// Shadow coefficient is 2
    case hanafi = 2

    var shadowCoefficient: Int { return self.rawValue }
}

public enum MidnightMethod: Int {
    /// From sunset to sunrise
    case standard
    /// From sunset to fajr
    case jafari
}

public enum HigherLatutudeAdjustment {
    case none
    case midNight
    case oneSeventh
    case angleBased
}
