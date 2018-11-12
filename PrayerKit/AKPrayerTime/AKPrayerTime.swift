//
//  AKPrayerTime.swift
//  PrayerKit
//
//  Created by Ashik Ahmad on 4/15/15.
//  Copyright (c) 2015 WNeeds. All rights reserved.
//

import UIKit

class AKPrayerTime {
    
    enum CalculationMethod {
        /// Muslim World League
        case MWL
        /// Islamic Society of North America
        case ISNA
        /// Egyptian General Authority of Survey
        case Egypt
        /// Umm al-Qura University, Makkah
        case Makkah
        /// University of Islamic Science, Karachi
        case Karachi
        /// Institute of Geophysics, University of Tehran
        case Tehran
        /// Shia Ithna Ashari, Leva Research Institute, Qum
        case Jafari
        /// Custom, these can be changed as user sets.
        case Custom
    }
    
    enum JuristicMethod: Int {
        /// Shafi'i, Maliki, Ja'fari, and Hanbali
        case Shafii = 0
        /// Hanafi
        case Hanafi = 1
        
        func toInt()->Int { return self.rawValue }
    }
    
    enum HigherLatutudeAdjustment {
        case none
        case midNight
        case oneSeventh
        case angleBased
    }
    
    enum OutputTimeFormat {
        case time24
        case time12
        case time12NoSuffix
        case float
        case date
    }
    
    enum TimeNames : String {
        case imsak
        case fajr
        case sunrise
        case dhuhr
        case asr
        case sunset
        case maghrib
        case isha
        
        func toString()->String {
            return self.rawValue.capitalized
        }
    }
    
    struct Coordinate {
        var latitude: Double
        var longitude: Double
        
        init(lat: Double, lng: Double) {
            latitude = lat
            longitude = lng
        }
    }

    struct MethodParams {

        enum MaghribParam {
            case angles(Double)
            case minutesAfterSunset(Double)
        }

        enum IshaParam {
            case angles(Double)
            case minutesAfterMaghrib(Double)
        }

        var fajrAngle: Double
        var maghrib: MaghribParam
        var isha: IshaParam
    }

    fileprivate enum Defaults {
        static let calendar = Calendar(identifier: .gregorian)
        static let componentsDMY = Set([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day])

        static let dayTimes: [TimeNames: Double] = [
            .fajr    : 5.0,
            .sunrise : 6.0,
            .dhuhr   : 12.0,
            .asr     : 13.0,
            .sunset  : 18.0,
            .maghrib : 18.0,
            .isha    : 18.0
        ]

        static var methodParams: [CalculationMethod: MethodParams] = [
            .MWL: MethodParams(fajrAngle: 18,
                               maghrib: .minutesAfterSunset(0),
                               isha: .angles(17)),

            .ISNA: MethodParams(fajrAngle: 15,
                                maghrib: .minutesAfterSunset(0),
                                isha: .angles(15)),

            .Egypt: MethodParams(fajrAngle: 19.5,
                                 maghrib: .minutesAfterSunset(0),
                                 isha: .angles(17.5)),

            .Makkah: MethodParams(fajrAngle: 18.5,
                                  maghrib: .minutesAfterSunset(0),
                                  isha: .minutesAfterMaghrib(90)),

            .Karachi: MethodParams(fajrAngle: 18,
                                   maghrib: .minutesAfterSunset(0),
                                   isha: .angles(18)),

            .Tehran: MethodParams(fajrAngle: 17.7,
                                  maghrib: .angles(4.5),
                                  isha: .angles(14)),

            .Jafari: MethodParams(fajrAngle: 16,
                                  maghrib: .angles(4),
                                  isha: .angles(14)),

            .Custom: MethodParams(fajrAngle: 18,
                                  maghrib: .minutesAfterSunset(0),
                                  isha: .angles(17))
        ]
    }

    //------------------------------------------------------
    // MARK: - Technical Settings
    //------------------------------------------------------
    
    /// number of iterations needed to compute times
    var numIterations:Int = 1

    /**
    Required parameters for calculation methods.
    None but the `.Custom` parameters should be changed where appropriate.
    Mostly, you should not be touching is directly.
    
    **Note:**
    Parameters are five-element arrays with following values:
    
     methodParams[method] = @[fa, ms, mv, is, iv];
     ------------------------------------------------------
     fa:  fajr angle
     ms:  maghrib selector (0 = angle; 1 = minutes after sunset)
     mv:  maghrib parameter value (in angle or minutes)
     is:  isha selector (0 = angle; 1 = minutes after maghrib)
     iv:  isha parameter value (in angle or minutes)
    */
//    var methodParams:[CalculationMethod: [Float]] = [
//        .MWL     : [18  , 1, 0  , 0, 17  ],
//        .ISNA    : [15  , 1, 0  , 0, 15  ],
//        .Egypt   : [19.5, 1, 0  , 0, 17.5],
//        .Makkah  : [18.5, 1, 0  , 1, 90  ],
//        .Karachi : [18  , 1, 0  , 0, 18  ],
//        .Tehran  : [17.7, 0, 4.5, 0, 14  ],
//        .Jafari  : [16  , 0, 4  , 0, 14  ],
//        .Custom  : [18  , 1, 0  , 0, 17  ]
//    ];

    //------------------------------------------------------
    // MARK: - Properties
    //------------------------------------------------------
    
    var offsets:[TimeNames: Double] = [
        .fajr    : 0,
        .sunrise : 0,
        .dhuhr   : 0,
        .asr     : 0,
        .sunset  : 0,
        .maghrib : 0,
        .isha    : 0
    ];
    
    
    /// Once 'computePrayerTimes' is called,
    /// computed values are stored here for reuse
    var currentPrayerTimes:[TimeNames: Double]?
    
    /// Prayer calculation methods.
    /// See `CalculationMethod` enums for more details
    var calculationMethod      = CalculationMethod.MWL
    /// Asr method, `Shafii` or `Hanafii`
    var asrJuristic            = JuristicMethod.Shafii
    /// Adjustment options for Higher Latitude
    var highLatitudeAdjustment = HigherLatutudeAdjustment.midNight
    /// Prayer time output format.
    var outputFormat           = OutputTimeFormat.time24
    
    // Not sure if it should be replaced by offsets[.Dhuhr]
    var dhuhrMinutes: Float = 0
    
    /// Coordinate of the place, times will be calculated for.
    var coordinate: Coordinate! {
        didSet {
            calculateJulianDate()
        }
    }
    
    /// Timezone of the place, times will be calculated for.
    var timeZone:Float   = AKPrayerTime.systemTimeZone()
    
    /// Date for which prayer times will be calculated.
    /// Defaults to today, when not set.
    var calcDate:Date! {
        didSet {
            calculateJulianDate()
        }
    }
    
    private lazy var jDate:Double = AKPrayerTime.julianDate(from: Date())
    
    //------------------------------------------------------
    // MARK: - Constructor
    //------------------------------------------------------
    
    init(lat:Double, lng:Double){
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
    
    //------------------------------------------------------
    // MARK: - Public Methods: Get prayer times
    //------------------------------------------------------
    
    /// Return prayer times for a given date, latitude, longitude and timeZone
    func getDatePrayerTimes(year:Int, month:Int, day:Int, latitude:Double, longitude:Double, tZone:Float)->[TimeNames: Any] {
        coordinate = Coordinate(lat: latitude, lng: longitude)
        
        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = day
        calcDate = Defaults.calendar.date(from: comp)
        
        timeZone = tZone
        
        jDate = AKPrayerTime.julianDate(year: year, month: month, day: day)
        
        let lonDiff = longitude / (15.0 * 24.0)
        jDate = jDate - lonDiff;
        return computeDayTimes()
    }
    
    /// Returns prayer times for a date(or today) when everything is set
    func getPrayerTimes()->[TimeNames: Any]? {
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

    func sorted(_ t: [TimeNames: Any]) -> [(TimeNames, Any)] {
        let seq: [AKPrayerTime.TimeNames] = [.fajr, .sunrise, .dhuhr, .asr, .sunset, .maghrib, .isha]
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
        Defaults.methodParams[.Custom] = params
        calculationMethod = .Custom
    }

    /// Set the angle for calculating Fajr
    func setFajrAngle(angle: Double) {
        setCustomParams { $0.fajrAngle = angle }
    }
    
    /// Set the angle for calculating Maghrib
    func setMaghribAngle(angle: Double) {
        setCustomParams { $0.maghrib = .angles(angle) }
    }
    
    /// Set the angle for calculating Isha
    func setIshaAngle(angle: Double) {
        setCustomParams { $0.isha = .angles(angle) }
    }
    
    /// Set the minutes after Sunset for calculating Maghrib
    func setMaghribMinutes(minutes: Double) {
        setCustomParams { $0.maghrib = .minutesAfterSunset(minutes) }
    }
    
    /// Set the minutes after Maghrib for calculating Isha
    func setIshaMinutes(minutes: Double) {
        setCustomParams { $0.isha = .minutesAfterMaghrib(minutes) }
    }
    
    //------------------------------------------------------
    // MARK: - Public Methods: Format Conversion
    //------------------------------------------------------
    
    /// Convert float hours to (hours, minutes)
    func floatToHourMinute(_ time:Double)->(hours:Int, minutes:Int)? {
        if time.isNaN {
            return nil
        }
        
        let ttime = fixHour(time + 0.5 / 60.0)  // add 0.5 minutes to round
        let hours = Int(floor(ttime))
        let minutes = Int(floor((ttime - Double(hours)) * 60.0))
        
        return (hours: hours, minutes: minutes)
    }
    
    /// Convert float hours to 24h format
    func floatToTime24(_ time:Double)->String {
        if let (hours, minutes) = floatToHourMinute(time) {
            return NSString(format: "%02d:%02d", hours, minutes) as String
        } else {
            return "---"
        }
    }
    
    /// Convert float hours to 12h format
    func floatToTime12(_ time:Double, noSuffix:Bool)->String {
        if let (hours, minutes) = floatToHourMinute(time) {
            return NSString(format: "%02d:%02d%@", (hours % 12), minutes, (noSuffix ? "" : ((hours > 12) ? " pm" : " am")) ) as String
        } else {
            return "---"
        }
    }
    
    /// Convert float hours to 12h format with no suffix
    func floatToTime12NS(_ time:Double)->String {
        return floatToTime12(time, noSuffix: true)
    }
    
    /// Convert float hours to NSDate
    func floatToNSDate(_ time:Double)->Date? {
        if let (hours, minutes) = floatToHourMinute(time) {
            var components = Defaults.calendar.dateComponents(Defaults.componentsDMY, from: calcDate)
            components.hour = hours
            components.minute = minutes
            return Defaults.calendar.date(from: components)
        } else {
            return nil
        }
    }
    
    //------------------------------------------------------
    // MARK: - Julian Date Calculation
    //------------------------------------------------------
    
    private func calculateJulianDate() {
        if let date = calcDate {
            if let latlng = coordinate {
                jDate = AKPrayerTime.julianDate(from: date)
                jDate = jDate - (latlng.longitude / (15.0 * 24.0))
            }
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
    
    // compute declination angle of sun and equation of time
    private func sunPosition(_ jd:Double)->(Double, Double) {
        let d = jd - 2451545.0;
        let g = DMath.fixAngle(357.529 + 0.98560028 * d)
        let q = DMath.fixAngle(280.459 + 0.98564736 * d)
        let L = DMath.fixAngle(q + (1.915 * DMath.dSin(g)) + (0.020 * DMath.dSin(2 * g)))
        
        //double R = 1.00014 - 0.01671 * [self dcos:g] - 0.00014 * [self dcos: (2*g)];
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
    private func computeTime(_ G:Double, t:Double)->Double {
        // Sun Declination
        let D:Double = sunDeclination(jDate + t)
        // Zawal
        let Z:Double = computeMidDay(t)

        let x1 = (DMath.dSin(D) * DMath.dSin(coordinate!.latitude))
        let x2 = (DMath.dCos(D) * DMath.dCos(coordinate!.latitude))
        let V:Double = DMath.dArcCos((-DMath.dSin(G) - x1) / x2) / 15.0
        
        if G > 90 {
            return Z - V
        } else {
            return Z + V
        }
    }
    
    // compute the time of Asr
    // Shafii: step=1, Hanafi: step=2
    private func computeAsr(step:Double, t:Double)->Double {
        let d = sunDeclination(jDate + t)
        let g = -DMath.dArcCot(step + DMath.dTan(abs(coordinate!.latitude - d)))
        return computeTime(g, t: t)
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
        
        let idk     = params.fajrAngle
        let fajr    = computeTime((180.0 - idk), t: t[.fajr]!)
        let sunrise = computeTime((180.0 - 0.833), t: t[.sunrise]!)
        let dhuhr   = computeMidDay(t[.dhuhr]!)
        let asr     = computeAsr(step: Double(1 + asrJuristic.toInt()), t: t[.asr]!)
        let sunset  = computeTime(0.833, t: t[.sunset]!)

        let maghrib: Double = {
            switch params.maghrib {
            case .angles(let angle):
                return computeTime(angle, t: t[.maghrib]!)
            case .minutesAfterSunset(let minutes):
                return sunset + minutes / 60.0
            }
        }()

        let isha: Double = {
            switch params.isha {
            case .angles(let angle):
                return computeTime(angle, t: t[.isha]!)
            case .minutesAfterMaghrib(let minutes):
                return maghrib + minutes / 60
            }
        }()

        let cTimes: [TimeNames: Double] = [
            .fajr    : fajr,
            .sunrise : sunrise,
            .dhuhr   : dhuhr,
            .asr     : asr,
            .sunset  : sunset,
            .maghrib : maghrib,
            .isha    : isha
        ]
        
        //Tune times here
        //Ctimes = [self tuneTimes:Ctimes];
        
        return cTimes;
    }
    
    // compute prayer times at given julian date
    private func computeDayTimes()->[TimeNames: Any] {
        //default times
        let times = Defaults.dayTimes;
        
        // Compute minimum once
        var t1 = computeTimes(times)
        
        // If need more iterations...
        if numIterations > 1 {
            for _ in 2...numIterations {
                t1 = computeTimes(times)
            }
        }
        
        var t2 = adjustTimes(t1)
        t2 = tuneTimes(t2)
        
        //Set prayerTimesCurrent here!!
        currentPrayerTimes = t2
        
        let t3 = adjustTimesFormat(t2)
        
        return t3
    }
    
    // Tune timings for adjustments
    // Set time offsets
    private func tune(offsetTimes: [TimeNames: Double]) {
        offsets = offsetTimes;
    }
    
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
    private func fixHour(_ a:Double)->Double {
        return DMath.wrap(a, min: 0, max: 24)
    }
    
    // adjust times in a prayer time array
    private func adjustTimes(_ times: [TimeNames: Double])-> [TimeNames: Double] {
        var ttimes = times
//        var dTime1:Double
//        var dTime2:Double

        for (timeName, time) in ttimes {
            ttimes[timeName] = time + (Double(timeZone) - coordinate!.longitude / 15.0);
        }
        
        ttimes[TimeNames.dhuhr] = ttimes[TimeNames.dhuhr]! + (Double(dhuhrMinutes) / 60.0); //Dhuhr
        
//        var params = Defaults.methodParams[calculationMethod]!
//        let val = params[1]
//
//        if (val == 1.0) { // Maghrib
//            dTime1 = ttimes[TimeNames.sunset]! + Double(params[2] / 60.0)
//            ttimes[TimeNames.maghrib] = dTime1
//        }
//
//        if params[3] == 1 { // Isha
//            dTime2 = ttimes[TimeNames.maghrib]! + Double(params[4] / 60.0)
//            ttimes[TimeNames.isha] = dTime2
//        }

        if (highLatitudeAdjustment != HigherLatutudeAdjustment.none){
            ttimes = adjustHighLatTimes(ttimes)
        }
        return ttimes;
    }
    
    // convert times array to given time format
    private func adjustTimesFormat(_ times: [TimeNames: Double])-> [TimeNames: Any] {
        var ttimes: [TimeNames: Any] = [TimeNames: Any]()
        
        for (timeName, time) in times {
            if (outputFormat == OutputTimeFormat.float) {
                ttimes[timeName] = time as AnyObject
            } else if (outputFormat == OutputTimeFormat.time12) {
                ttimes[timeName] = floatToTime12(time, noSuffix: false)
            } else if (outputFormat == OutputTimeFormat.time12NoSuffix) {
                ttimes[timeName] = floatToTime12(time, noSuffix:true)
            } else if (outputFormat == OutputTimeFormat.time24){
                ttimes[timeName] = floatToTime24(time)
            } else {
                // floatToNSDate can return nil, if time is invalid
                ttimes[timeName] = floatToNSDate(time)
            }
        }
        return ttimes;
    }
    
    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    private func adjustHighLatTimes(_ times: [TimeNames: Double])-> [TimeNames: Double] {
        var ttimes = times
        let params = Defaults.methodParams[calculationMethod]!
        
        let nightTime = timeDiff(ttimes[TimeNames.sunset]!, time2:ttimes[TimeNames.sunrise]!) // sunset to sunrise
        
        // Adjust Fajr
        let fajrDiff = nightPortion(angle: params.fajrAngle) * nightTime;
        if (ttimes[TimeNames.fajr]!.isNaN || timeDiff(ttimes[TimeNames.fajr]!, time2: ttimes[TimeNames.sunrise]!) > fajrDiff) {
            ttimes[TimeNames.fajr] = ttimes[TimeNames.sunrise]! - fajrDiff
        }
        
        // Adjust Isha
        let ishaAngle:Double = {
            switch params.isha {
            case .angles(let angle): return angle
            default: return 18.0
            }
        }()
        let ishaDiff:Double = nightPortion(angle: ishaAngle) * nightTime
        if (ttimes[TimeNames.isha]!.isNaN || timeDiff(ttimes[TimeNames.sunset]!, time2: ttimes[TimeNames.isha]!) > ishaDiff) {
            ttimes[TimeNames.isha] = ttimes[TimeNames.sunset]! + ishaDiff
        }
        
        // Adjust Maghrib
        let maghribAngle:Double = {
            switch params.maghrib {
            case .angles(let angle): return angle
            default: return 4.0
            }
        }()
        let maghribDiff:Double = nightPortion(angle: maghribAngle) * nightTime
        if (ttimes[TimeNames.maghrib]!.isNaN || timeDiff(ttimes[TimeNames.sunset]!, time2: ttimes[TimeNames.maghrib]!) > maghribDiff) {
            ttimes[TimeNames.maghrib] = ttimes[TimeNames.sunset]! + maghribDiff
        }
        
        return ttimes;
    }
    
    // the night portion used for adjusting times in higher latitudes
    private func nightPortion(angle: Double)-> Double {
        var calc:Double
        
        switch highLatitudeAdjustment {
        case .none       : calc = 0.0
        case .angleBased : calc = angle / 60.0
        case .midNight   : calc = 0.5
        case .oneSeventh : calc = 0.14286
        }
        
        return calc;
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

// ------------------------------------------------------
// MARK: - Trigonometric Functions
// ------------------------------------------------------

class DMath {
    class func wrap(_ a: Double, min: Double, max: Double)-> Double {
        var aa = a
        let range = max - min
        aa.formTruncatingRemainder(dividingBy: range)
        if aa < min { aa += range }
        if aa > max { aa -= range }
        return aa
    }
    
    // range reduce angle in degrees.
    class func fixAngle(_ a: Double)-> Double {
        return wrap(a, min: 0, max: 360)
    }
    
    // radian to degree
    class func radiansToDegrees(_ alpha: Double) -> Double{
        return ((alpha*180.0) / Double.pi);
    }
    
    // deree to radian
    class func degreesToRadians(_ alpha: Double)-> Double {
        return ((alpha*Double.pi)/180.0);
    }
    
    // degree sin
    class func dSin(_ d: Double)-> Double {
        return sin(degreesToRadians(d))
    }
    
    // degree cos
    class func dCos(_ d: Double)-> Double {
        return cos(degreesToRadians(d))
    }
    
    // degree tan
    class func dTan(_ d: Double)-> Double {
        return tan(degreesToRadians(d))
    }
    
    // degree arcsin
    class func dArcSin(_ x: Double)-> Double {
        let val = asin(x)
        return radiansToDegrees(val)
    }
    
    // degree arccos
    class func dArcCos(_ x: Double)-> Double {
        let val = acos(x);
        return radiansToDegrees(val)
    }
    
    // degree arctan
    class func dArcTan(_ x: Double)-> Double {
        let val = atan(x);
        return radiansToDegrees(val)
    }
    
    // degree arctan2
    class func dArcTan2(_ y: Double, x: Double)-> Double {
        let val = atan2(y, x);
        return radiansToDegrees(val)
    }
    
    // degree arccot
    class func dArcCot(_ x: Double)-> Double {
        let val = atan2(1.0, x);
        return radiansToDegrees(val)
    }
}
