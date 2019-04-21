//
//  AKPrayerTime.swift
//  PrayerKit
//
//  Created by Ashik Ahmad on 4/15/15.
//  Copyright (c) 2015 WNeeds. All rights reserved.
//

import UIKit

public final class AKPrayerTime {

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
    }
    
    public enum JuristicMethod: Int {

        /// Shafi'i, Maliki, Ja'fari, and Hanbali
        case shafii = 0

        /// Hanafi
        case hanafi = 1
        
        func toInt()->Int { return self.rawValue }
    }

    public enum MidnightMethod: Int {
        case standard
        case jafari
    }
    
    public enum HigherLatutudeAdjustment {
        case none
        case midNight
        case oneSeventh
        case angleBased
    }
    
    public enum TimeNames : String {
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
        
        public func toString()->String {
            return self.rawValue.capitalized
        }
    }
    
    public struct Coordinate {
        var latitude: Double
        var longitude: Double
        var elevation: Double
        
        init(lat: Double, lng: Double, elv: Double = 0) {
            latitude = lat
            longitude = lng
            elevation = elv
        }
    }

    public enum AnglesOrMinutes {
        case angles(Double)
        case minutes(Double)
    }
    
    struct MethodParams {
        var fajrAngle: Double
        var maghrib: AnglesOrMinutes
        var isha: AnglesOrMinutes
        var midnight: MidnightMethod
    }

    fileprivate enum Defaults {
        static let calendar = Calendar(identifier: .gregorian)
        static let componentsDMY = Set([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day])

        static let dayTimes: [TimeNames: Double] = [
            .imsak   : 5.0,
            .fajr    : 5.0,
            .sunrise : 6.0,
            .dhuhr   : 12.0,
            .asr     : 13.0,
            .sunset  : 18.0,
            .maghrib : 18.0,
            .isha    : 18.0
        ]

        /**
         Required parameters for calculation methods.
         None but the `.Custom` parameters should be changed where appropriate.
         Mostly, you should not be touching is directly. Use set** methods instead
         as appropriate.
         */
        static var methodParams: [CalculationMethod: MethodParams] = [
            .mwl: MethodParams(
                fajrAngle: 18,
                maghrib: .minutes(0),
                isha: .angles(17),
                midnight: .standard),

            .isna: MethodParams(
                fajrAngle: 15,
                maghrib: .minutes(0),
                isha: .angles(15),
                midnight: .standard),

            .egypt: MethodParams(
                fajrAngle: 19.5,
                maghrib: .minutes(0),
                isha: .angles(17.5),
                midnight: .standard),

            // fajrAngle was 19 degrees before 1430 hijri
            .makkah: MethodParams(
                fajrAngle: 18.5,
                maghrib: .minutes(0),
                isha: .minutes(90),
                midnight: .standard),

            .karachi: MethodParams(
                fajrAngle: 18,
                maghrib: .minutes(0),
                isha: .angles(18),
                midnight: .standard),

            .tehran: MethodParams(
                fajrAngle: 17.7,
                maghrib: .angles(4.5),
                isha: .angles(14),
                midnight: .jafari),

            .jafari: MethodParams(
                fajrAngle: 16,
                maghrib: .angles(4),
                isha: .angles(14),
                midnight: .jafari),

            .custom: MethodParams(
                fajrAngle: 18,
                maghrib: .minutes(0),
                isha: .angles(17),
                midnight: .standard)
        ]
    }

    //------------------------------------------------------
    // MARK: - Technical Settings
    //------------------------------------------------------
    
    /// number of iterations needed to compute times
    var numIterations:Int = 2

    //------------------------------------------------------
    // MARK: - Properties
    //------------------------------------------------------
    
    public var offsets:[TimeNames: Double] = [
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
    public var currentPrayerTimes:[TimeNames: Time]?
    
    /// Prayer calculation methods.
    /// See `CalculationMethod` enums for more details
    public var calculationMethod      = CalculationMethod.mwl
    /// Asr method, `Shafii` or `Hanafii`
    public var asrJuristic            = JuristicMethod.shafii
    /// Adjustment options for Higher Latitude
    public var highLatitudeAdjustment = HigherLatutudeAdjustment.midNight
    /// Prayer time output format.
//    public var outputFormat           = OutputTimeFormat.time24

    public var imsakSettings: AnglesOrMinutes = .minutes(10)
    
    // Not sure if it should be replaced by offsets[.Dhuhr]
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
    public func getDatePrayerTimes(year: Int, month: Int, day: Int, latitude: Double, longitude: Double, tZone: Float)-> [TimeNames: Time] {
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
    public func getPrayerTimes()->[TimeNames: Time]? {
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

    public func sorted(_ t: [TimeNames: Time]) -> [(TimeNames, Time)] {
        let seq: [AKPrayerTime.TimeNames] = [.imsak, .fajr, .sunrise,
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
        guard let mp = Defaults.methodParams[calculationMethod]
            else { return }
        var params = mp
        changes(&params)
        Defaults.methodParams[.custom] = params
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
    private func computeMidDay(_ t:Double)->Double {
        let T = equationOfTime(jDate + t)
        return fixHour(12 - T)
    }
    
    // compute time for a given angle G
    private func sunAngleTime(_ G:Double, t:Double, ccw: Bool)-> Double {
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
    private func computeAsr(step: Double, t: Double)-> Double {
        let d = sunDeclination(jDate + t)
        let g = -DMath.dArcCot(step + DMath.dTan(abs(coordinate!.latitude - d)))
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
    private func computeTimes(_ times: [TimeNames: Double])-> [TimeNames: Double] {
        var t = dayPortion(times)
        let params = Defaults.methodParams[calculationMethod]!
        
        var cTimes: [TimeNames: Double] = [:]

        if case let .angles(angle) = imsakSettings {
            cTimes[.imsak] = sunAngleTime(angle, t: t[.imsak]!, ccw: true)
        }

        let riseSet = riseSetAngle()
        cTimes[.fajr]    = sunAngleTime(params.fajrAngle, t: t[.fajr]!, ccw: true)
        cTimes[.sunrise] = sunAngleTime(riseSet, t: t[.sunrise]!, ccw: true)
        cTimes[.dhuhr]   = computeMidDay(t[.dhuhr]!)
        cTimes[.asr]     = computeAsr(step: Double(1 + asrJuristic.toInt()), t: t[.asr]!)
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
    private func computeDayTimes()-> [TimeNames: Time] {
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

        let nightTime: Double
        switch Defaults.methodParams[calculationMethod]!.midnight {
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

    private func tuneTimes(_ times:[TimeNames: Double])-> [TimeNames: Double] {
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
    private func adjustTimes(_ times: [TimeNames: Double])-> [TimeNames: Double] {
        var ttimes = times

        let offset = (Double(timeZone) - coordinate!.longitude / 15.0)
        ttimes = ttimes.mapValues { $0 + offset }

        if (highLatitudeAdjustment != .none){
            ttimes = adjustHighLatTimes(ttimes)
        }
        
        let params = Defaults.methodParams[calculationMethod]!
        
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
        ttimes[TimeNames.dhuhr] = ttimes[TimeNames.dhuhr]! + (Double(dhuhrMinutes) / 60.0);
        
        return ttimes;
    }

    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    private func adjustHighLatTimes(_ times: [TimeNames: Double])-> [TimeNames: Double] {

        guard let params = Defaults.methodParams[calculationMethod],
            let sunrise = times[TimeNames.sunrise],
            let sunset = times[TimeNames.sunset]
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
    private func dayPortion(_ times: [TimeNames: Double])-> [TimeNames: Double] {
        var ttimes = [TimeNames: Double]()
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
 1. Midnight (Based on Sunset-Fajr or Sunset-sunrise)
 2. Qiyam Al-lyle (Based on Sunset-Fajr or Sunset-sunrise)



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

 */
