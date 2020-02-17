//
//  AKPrayerTime.swift
//  PrayerKit
//  By 𝔸𝕤𝕙𝕚𝕜 𝕌𝕕𝕕𝕚𝕟 𝔸𝕙𝕞𝕒𝕕
//
//  Created by Ashik Ahmad on 4/15/15.
//  Copyright (c) 2015 WNeeds. All rights reserved.
//

import UIKit

public final class AKPrayerTime {

    // MARK: -
    public enum AnglesOrMinutes {
        case angles(Double)
        case minutes(Double)
    }

    // MARK: -
    struct MethodParams {
        var fajrAngle: Double
        var maghrib: AnglesOrMinutes
        var isha: AnglesOrMinutes
        var midnight: MidnightMethod
    }

    fileprivate enum Defaults {
        static let calendar = Calendar(identifier: .gregorian)
        static let componentsDMY = Set([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day])

        static let dayTimes: [PrayerName: Double] = [
            .imsak   : 5.0,
            .fajr    : 5.0,
            .sunrise : 6.0,
            .dhuhr   : 12.0,
            .asr     : 13.0,
            .sunset  : 18.0,
            .maghrib : 18.0,
            .isha    : 18.0
        ]

    }

    //------------------------------------------------------
    // MARK: - Technical Settings
    //------------------------------------------------------
    
    /// number of iterations needed to compute times
    var numIterations:Int = 2

    //------------------------------------------------------
    // MARK: - Basic Configurations
    //------------------------------------------------------

    /// Prayer calculation methods.
    /// See `CalculationMethod` enums for more details
    public var calculationMethod      = CalculationMethod.mwl {
        didSet {
            if calculationMethod != .custom {
                params = calculationMethod.params
            }
        }
    }
    /// Asr method, `Shafii` or `Hanafii`
    public var asrJuristic            = AsrJuristicMethod.shafii

    //------------------------------------------------------
    // MARK: - Optional Configurations
    //------------------------------------------------------

    //------------------------------------------------------
    // MARK: - Advanced Configurations
    //------------------------------------------------------


    public var offsets:[PrayerName: Double] = [
        .imsak   : 0,
        .fajr    : 0,
        .sunrise : 0,
        .dhuhr   : 0,
        .asr     : 0,
        .sunset  : 0,
        .maghrib : 0,
        .isha    : 0,
        .midnight: 0,
        .qiyam   : 0
    ];
    
    /// Once 'computePrayerTimes' is called,
    /// computed values are stored here for reuse
    public var currentPrayerTimes:[PrayerName: Time]?

    public var expectedPrayerTimes: [PrayerName] = PrayerName.all
    
    /// Adjustment options for Higher Latitude
    public var highLatitudeAdjustment = HigherLatutudeAdjustment.midNight

    public var imsakSettings: AnglesOrMinutes = .minutes(10)
    
    // Some definition of dhuhr requires adding aprox. 1 minute (65 seconds max as calculated)
    public var dhuhrMinutes: Float = 0
    
    /// Coordinate of the place, times will be calculated for.
    public var coordinate: Coordinate! {
        didSet {
            calculateJulianDate()
        }
    }
    
    /// Timezone of the place, times will be calculated for.
    public var timeZone:Float   = AKPrayerTime.systemTimeZone()
    
    /// Date for which prayer times will be calculated.
    /// Defaults to today, when not set.
    public var calcDate:Date! {
        didSet {
            calculateJulianDate()
        }
    }

    var params: MethodParams = CalculationMethod.mwl.params
    
    private lazy var jDate:Double = AKPrayerTime.julianDate(from: Date())
    
    //------------------------------------------------------
    // MARK: - Constructor
    //------------------------------------------------------
    
    public init(lat:Double, lng:Double){
        coordinate = Coordinate(lat: lat, lng: lng)
        calcDate = Date()
    }
    
    //------------------------------------------------------
    // MARK: - Utility Methods (Type Methods)
    //------------------------------------------------------
    
    class func systemTimeZone()->Float {
        let timeZone = TimeZone.current
        return Float(timeZone.secondsFromGMT())/3600.0
    }
    
    class func dayLightSavingOffset()->Double {
        let timeZone = TimeZone.current
        return Double(timeZone.daylightSavingTimeOffset(for: Date()))
    }
    
    /// Sunrise/sunset angle with elevation adjustment
    private func riseSetAngle() -> Double {
//        let earthRad: Double = 6371009; // in meters
//        let angle = DMath.dArcCos(earthRad/(earthRad + coordinate.elevation));
        let angle = 0.0347 * sqrt(coordinate.elevation); // an approximation
        return 0.833 + angle;
    }
    
    //------------------------------------------------------
    // MARK: - Public Methods: Get prayer times
    //------------------------------------------------------
    
    /// Return prayer times for a given date, latitude, longitude and timeZone
    public func getDatePrayerTimes(year: Int, month: Int, day: Int, latitude: Double, longitude: Double, tZone: Float)-> [PrayerName: Time] {
        coordinate = Coordinate(lat: latitude, lng: longitude)
        
        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = day
        calcDate = Defaults.calendar.date(from: comp)
        
        timeZone = tZone
        
        // This may not be necessary
        jDate = AKPrayerTime.julianDate(year: year, month: month, day: day)
        let lonDiff = longitude / (15.0 * 24.0)
        jDate = jDate - lonDiff;
        
        return computeDayTimes()
    }
    
    /// Returns prayer times for a date(or today) when everything is set
    public func getPrayerTimes()->[PrayerName: Time]? {
        // If coordinate is not set, cannot obtain prayer times
        if coordinate == nil {
            return nil
        }
        
        // If date is not set, set today as calcDate
        if calcDate == nil {
            calcDate = Date()
        }
        
        // jDate should be autometically set already
        return computeDayTimes()
    }

    public func sorted(_ t: [PrayerName: Time]) -> [(PrayerName, Time)] {
        let seq: [PrayerName] = [.imsak, .fajr, .sunrise,
                                .dhuhr, .asr, .sunset,
                                .maghrib, .isha, .midnight, .qiyam]
        return t.sorted {a,b in
            (seq.firstIndex(of: a.key) ?? 0) < (seq.firstIndex(of: b.key) ?? 0)
        }
    }
    
    //------------------------------------------------------
    // MARK: - Public Methods: Configurations
    //------------------------------------------------------
    
    /// Set custom values for calculation parameters
    private func setCustomParams(_ changes: (inout MethodParams)->Void) {
        changes(&params)
//        guard let mp = Defaults.methodParams[calculationMethod]
//            else { return }
//        var params = mp
//        changes(&params)
//        Defaults.methodParams[.custom] = params
        calculationMethod = .custom
    }

    /// Set the angle for calculating Fajr
    public func setFajrAngle(angle: Double) {
        setCustomParams { $0.fajrAngle = angle }
    }
    
    /// Set the angle for calculating Maghrib
    public func setMaghribAngle(angle: Double) {
        setCustomParams { $0.maghrib = .angles(angle) }
    }
    
    /// Set the angle for calculating Isha
    public func setIshaAngle(angle: Double) {
        setCustomParams { $0.isha = .angles(angle) }
    }
    
    /// Set the minutes after Sunset for calculating Maghrib
    public func setMaghribMinutes(minutes: Double) {
        setCustomParams { $0.maghrib = .minutes(minutes) }
    }
    
    /// Set the minutes after Maghrib for calculating Isha
    public func setIshaMinutes(minutes: Double) {
        setCustomParams { $0.isha = .minutes(minutes) }
    }

    public func setMidnightMethod(_ method: MidnightMethod) {
        setCustomParams { $0.midnight = method }
    }
    
    //------------------------------------------------------
    // MARK: - Julian Date Calculation
    //------------------------------------------------------
    
    private func calculateJulianDate() {
        if let date = calcDate, let latlng = coordinate {
            let jdt = AKPrayerTime.julianDate(from: date)
            jDate = jdt - (latlng.longitude / (15.0 * 24.0))
        }
    }
    
    private class func julianDate(from date:Date)->Double {
        let components = Defaults.calendar.dateComponents(Defaults.componentsDMY, from: Date())
        return julianDate(year: components.year ?? 0,
                          month: components.month ?? 0,
                          day: components.day ?? 0)
    }
    
    private class func julianDate(year:Int, month:Int, day:Int)->Double {
        var yyear = year, mmonth = month, dday = day
        if mmonth < 2 {
            yyear -= 1
            mmonth += 12
        }
        
        let A = floor(Double(yyear)/100.0)
        let B = 2.0 - A + floor(A/4.0)
        
        return floor(365.25 * (Double(yyear) + 4716.0))
            + floor(30.6001 * (Double(mmonth) + 1.0))
            + Double(dday) + B - 1524.5
    }
    
    //------------------------------------------------------
    // MARK: - Calculation Functions
    //------------------------------------------------------
    
    // References:
    // http://praytimes.org/calculation/
    
    /**
     Compute declination angle of sun and equation of time
     - Parameters:
       - jd: Julian date in double
     - Returns: Tuple of (Declination of sun, Equation of time) as (Double, Double)
     */
    private func sunPosition(_ jd:Double)->(Double, Double) {
        let d = jd - 2451545.0;
        let g = DMath.fixAngle(357.529 + 0.98560028 * d)
        let q = DMath.fixAngle(280.459 + 0.98564736 * d)
        let L = DMath.fixAngle(q + (1.915 * DMath.dSin(g)) + (0.020 * DMath.dSin(2 * g)))
        
//        let R = 1.00014 - 0.01671 * DMath.dCos(g) - 0.00014 * DMath.dCos(2*g)
        let e = 23.439 - (0.00000036 * d)
        var RA = DMath.dArcTan2(DMath.dCos(e) * DMath.dSin(L), x: DMath.dCos(L)) / 15.0
        RA = fixHour(RA);

        // Declination of the sun
        let D = DMath.dArcSin(DMath.dSin(e) * DMath.dSin(L))
        // Equation of time
        let EqT = q / 15.0 - RA;
        
        return (D, EqT);
    }
    
    // compute equation of time
    private func equationOfTime(_ jd:Double)->Double {
        let (_, EqT) = sunPosition(jd)
        return EqT
    }
    
    // compute declination angle of sun
    private func sunDeclination(_ jd:Double)->Double {
        let (D, _) = sunPosition(jd)
        return D
    }
    
    // compute mid-day (Dhuhr, Zawal) time
    private func computeMidDay(_ t: Double)->Double {
        let T = equationOfTime(jDate + t)
        return fixHour(12 - T)
    }
    
    // compute time for a given angle G, and day portion t
    private func sunAngleTime(_ G: Double, t: Double, ccw: Bool)-> Double {
        // Sun Declination
        let D:Double = sunDeclination(jDate + t)
        // Zawal
        let Z:Double = computeMidDay(t)

        let x1 = (DMath.dSin(D) * DMath.dSin(coordinate!.latitude))
        let x2 = (DMath.dCos(D) * DMath.dCos(coordinate!.latitude))
        let V:Double = DMath.dArcCos((-DMath.dSin(G) - x1) / x2) / 15.0
        
        return Z + (ccw ? -V : V)
    }
    
    // compute the time of Asr
    // Shafii: step=1, Hanafi: step=2
    private func computeAsr(step: Int, t: Double)-> Double {
        let d = sunDeclination(jDate + t)
        let g = -DMath.dArcCot(Double(step) + DMath.dTan(abs(coordinate!.latitude - d)))
        return sunAngleTime(g, t: t, ccw: false)
    }
    
    //------------------------------------------------------
    // MARK: - Misc Functions
    //------------------------------------------------------
    
    // compute the difference between two times
    private func timeDiff(_ time1:Double, time2:Double)->Double {
        return fixHour(time2 - time1)
    }

    //------------------------------------------------------
    // MARK: - Compute Prayer Times
    //------------------------------------------------------
    
    // compute prayer times at given julian date
    private func computeTimes(_ times: [PrayerName: Double])-> [PrayerName: Double] {
        var t = dayPortion(times)

        var cTimes: [PrayerName: Double] = [:]

        if case let .angles(angle) = imsakSettings {
            cTimes[.imsak] = sunAngleTime(angle, t: t[.imsak]!, ccw: true)
        }

        let riseSet = riseSetAngle()
        cTimes[.fajr]    = sunAngleTime(params.fajrAngle, t: t[.fajr]!, ccw: true)
        cTimes[.sunrise] = sunAngleTime(riseSet, t: t[.sunrise]!, ccw: true)
        cTimes[.dhuhr]   = computeMidDay(t[.dhuhr]!)
        cTimes[.asr]     = computeAsr(step: asrJuristic.shadowCoefficient, t: t[.asr]!)
        cTimes[.sunset]  = sunAngleTime(riseSet, t: t[.sunset]!, ccw: false)

        if case let .angles(angle) = params.maghrib {
            cTimes[.maghrib] = sunAngleTime(angle, t: t[.maghrib]!, ccw: false)
        }
        
        if case let .angles(angle) = params.isha {
            cTimes[.isha] = sunAngleTime(angle, t: t[.isha]!, ccw: false)
        }

        return cTimes;
    }
    
    // compute prayer times at given julian date
    private func computeDayTimes()-> [PrayerName: Time] {
        //default times
        var times = Defaults.dayTimes;
        
        // Compute minimum once
        times = computeTimes(times)
        
        // If need more iterations...
        if numIterations > 1 {
            for _ in 2...numIterations {
                times = computeTimes(times)
            }
        }
        
        times = adjustTimes(times)

        // FIXME: To calculate nightTime, sunrise/fajr should be for next date.
        let nightTime: Double
        switch params.midnight {
        case .standard:
            nightTime = timeDiff(times[.sunset]!, time2: times[.sunrise]!)
        case .jafari:
            nightTime = timeDiff(times[.sunset]!, time2: times[.fajr]!)
        }

        times[.midnight] = times[.sunset]! + nightTime/2
        times[.qiyam] = times[.sunset]! + nightTime*2/3
        
        times = tuneTimes(times)
        

        let finalTimes = times.mapValues { Time(duration: $0) } //adjustTimesFormat(t2)
        //Set prayerTimesCurrent here!!
        currentPrayerTimes = finalTimes

        return finalTimes
    }
    
    // Tune timings for adjustments
    // Set time offsets
//    private func tune(offsetTimes: [TimeNames: Double]) {
//        offsets = offsetTimes;
//    }

    private func tuneTimes(_ times:[PrayerName: Double])-> [PrayerName: Double] {
        var ttimes = times
        for (pName, time) in times {
            //if(i==5)
            //NSLog(@"Normal: %d - %@", i, [times objectAtIndex:i]);
            let off = offsets[pName]! / 60.0
            let oTime = time + off
            ttimes[pName] = oTime
            //if(i==5)
            //NSLog(@"Modified: %d - %@", i, [times objectAtIndex:i]);
        }

        return ttimes;
    }
    
    // range reduce hours to 0..23
    private func fixHour(_ a: Double)-> Double {
        return DMath.wrap(a, min: 0, max: 24)
    }
    
    // adjust times in a prayer time array
    private func adjustTimes(_ times: [PrayerName: Double])-> [PrayerName: Double] {
        var ttimes = times

        let offset = (Double(timeZone) - coordinate!.longitude / 15.0)
        ttimes = ttimes.mapValues { $0 + offset }

        if (highLatitudeAdjustment != .none){
            ttimes = adjustHighLatTimes(ttimes)
        }
        
        // Minutes based adjustments
        if case let .minutes(min) = imsakSettings {
            ttimes[.imsak] = ttimes[.fajr]! - min / 60.0
        }
        if case let .minutes(min) = params.maghrib {
            ttimes[.maghrib] = ttimes[.sunset]! + min / 60.0
        }
        if case let .minutes(min) = params.isha {
            ttimes[.isha] = ttimes[.maghrib]! + min / 60.0
        }
        
        //Dhuhr
        ttimes[PrayerName.dhuhr] = ttimes[PrayerName.dhuhr]! + (Double(dhuhrMinutes) / 60.0);
        
        return ttimes;
    }

    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    private func adjustHighLatTimes(_ times: [PrayerName: Double])-> [PrayerName: Double] {

        guard let sunrise = times[PrayerName.sunrise],
            let sunset = times[PrayerName.sunset]
            else { return times }

        var ttimes = times

        // sunset to sunrise
        let nightTime = timeDiff(sunset, time2: sunrise)

        if let imsak = ttimes[.imsak], case let .angles(angle) = imsakSettings {
            ttimes[.imsak] = adjustHLTime(
                time: imsak, base: sunrise,
                angle: angle, night: nightTime, ccw: true)
        }

        if let fajr = ttimes[.fajr] {
            ttimes[.fajr] = adjustHLTime(
                time: fajr, base: sunrise,
                angle: params.fajrAngle, night: nightTime, ccw: true)
        }

        if let maghrib = ttimes[.maghrib], case let .angles(angle) = params.maghrib {
            ttimes[.maghrib] = adjustHLTime(
                time: maghrib, base: sunset,
                angle: angle, night: nightTime, ccw: false)
        }

        if let isha = ttimes[.isha], case let .angles(angle) = params.isha {
            ttimes[.isha] = adjustHLTime(
                time: isha, base: sunset,
                angle: angle, night: nightTime, ccw: false)
        }

        return ttimes;
    }

    private func adjustHLTime(time: Double, base: Double, angle: Double, night: Double, ccw: Bool) -> Double {
        var newTime = time
        let portion = nightPortion(angle: angle, night: night)
        let diff = ccw ? timeDiff(time, time2: base) : timeDiff(base, time2: time)
        if diff.isNaN || diff > portion {
            newTime = base + (ccw ? -portion : portion)
        }
        return newTime
    }
    
    // the night portion used for adjusting times in higher latitudes
    private func nightPortion(angle: Double, night: Double)-> Double {
        var calc:Double
        
        switch highLatitudeAdjustment {
        case .none       : calc = 0.0
        case .angleBased : calc = angle / 60.0
        case .midNight   : calc = 0.5
        case .oneSeventh : calc = 0.14286
        }
        
        return calc * night;
    }
    
    // convert hours to day portions
    private func dayPortion(_ times: [PrayerName: Double])-> [PrayerName: Double] {
        var ttimes = [PrayerName: Double]()
        for (pName, time) in times {
            let timeH = time / 24.0
            ttimes[pName] = timeH
        }
        return ttimes
    }
}

/*
 STEPS FOR PRAYER TIME CALCULATION
 ---------------------------------
 1. Calculate julian date
 2. Calculate sun declination and equation of time for julian date & lat-lng
 3. Iterate computeTimes starting with default day times
 4. Adjust times
 5. Tune offsets
 6. Format

 BASE TIMES (Must be Angle-based calculation)
 --------------------------------------------
 0. Mid-day (Dhuhr)
 1. Sunrise
 2. Sunset
 3. Asr

 SECONDARY TIMES (May depend on Base times)
 ------------------------------------------
 1. Fajr (Based on Sunrise or angle-based)
 2. Maghrib(Based on Sunset or angle-based)
 3. Isha (Based on Maghrib or angle-based)
 4. Imsak (Based on Fajr or angle-based)

 CALCULATED TIMES (Relative to base times)
 -----------------------------------------
 1. Midnight (Based on Sunset-Fajr or Sunset-Sunrise)
 2. Qiyam Al-lyle (Based on Sunset-Fajr or Sunset-Sunrise)

 TIMES: Description
 -----------------------------------------
 * Fajr: When the sky begin to lighten. Dawn.
 * Sunrise: The time at which the first part of the sun appears above the horizon.
 * Dhuhr: When the sun begin to decline after reaching it's highest point in the sky.
 * Asr: The time when length of any objects shadow reaches a factor of the length of the object itself plus the length of that object's shadow at noon. The factor is either 1 or 2 accroding to different school of thoughts.
 * Sunset: The time at which the last part of the sun disappears below the horizon.
 * Maghrib: Soon after sunset.
 * Isha: The time at which the darkness falls and there is no scattered light in the sky.
 * Midnight: The mean time from sunset to sunrise (or from sunset to Fajr in some school of thoughts)


 Declination is calculated with the following formula:
 d = 23.45 * sin [360 / 365 * (284 + N)]

 Where:
 d = declination
 N = day number, January 1 = day 1

 ===========================================
 FEATURES TODO
 ===========================================
 -[x] Separate time format from calculation flow
 -[ ] Get prayer times for array/range of dates (i.e. for week or month)
 -[ ] Get current prayer time: time name, start time, remaining time

 ===========================================
 CALCULATIONS
 ===========================================

 // Date passed after noon of 1st January, 2000 (when jd = 2451545.0)
 jd2k = 2451545.0;
 d = jd - jd2k;  // jd is the given Julian date

 // Mean anomaly of the Sun, in degrees. Need to reduce to 0-360 range.
 g = 357.529 + 0.98560028 * d;
 // Mean longitude of the Sun, in degrees. Need to reduce to 0-360 range.
 q = 280.459 + 0.98564736 * d;
 // Geocentric apparent ecliptic longitude of the Sun (adjusted for aberration), in degrees. Need to reduce to 0-360 range.
 L = q + 1.915* sin(g) + 0.020* sin(2*g);

 // The distance of the Sun from the Earth aproximated, in astronomical units (AU)
 R = 1.00014 - 0.01671 * cos(g) - 0.00014 * cos(2*g);
 // Mean obliquity of the ecliptic, in degrees
 e = 23.439 - 0.00000036* d;
 // Sun's right ascension
 RA = arctan2(cos(e)* sin(L), cos(L))/ 15;
 // declination of the Sun
 D = arcsin(sin(e)* sin(L));
 // Equation of time
 EqT = q/15 - RA;

 // Dhuhr
 -------------------
 Dhuhr = 12 + TimeZone - Lng/15 - EqT

 // Sun at Angle
 -------------------
 The time difference between the mid-day and the time at which sun reaches an angle α below the horizon can be computed using the following formula:

 T(α) = 1/15 * arccos( (-sin(α) - sin(L)*sin(D)) / (cos(L)*cos(D)) )

 // Sunrise/Sunset
 -------------------
 Astronomical sunrise and sunset occur at α=0. However, due to the refraction of light by terrestrial atmosphere, actual sunrise appears slightly before astronomical sunrise and actual sunset occurs after astronomical sunset. Actual sunrise and sunset can be computed using the following formulas:

 Sunrise = Dhuhr - T(0.833)
 Sunset = Dhuhr + T(0.833)

 // Asr
 -------------------
 The following formula computes the time difference between the mid-day and the time at which the object's shadow equals t times the length of the object itself plus the length of that object's shadow at noon:

 A(t) = 1/15 * arccos( (sin( arccot(t + tan(L-D)))) - sin(L)*sin(D)) / (cos(L)*cos(D)) )

 So, Asr is,
 Asr = Dhuhr + A(1); // For Shafi'i, Maliki, Ja'fari, and Hanbali school of thoughts
 Asr = Dhuhr + A(2); // For Hanafi school of thoughts
 */
