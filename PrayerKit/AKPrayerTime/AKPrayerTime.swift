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
        case MWL     /// Muslim World League
        case ISNA    /// Islamic Society of North America
        case Egypt   /// Egyptian General Authority of Survey
        case Makkah  /// Umm al-Qura University, Makkah
        case Karachi /// University of Islamic Science, Karachi
        case Tehran  /// Institute of Geophysics, University of Tehran
        case Jafari  /// Shia Ithna Ashari, Leva Research Institute, Qum
        case Custom
    }
    
    enum JuristicMethod {
        case Shafii /// Shafi'i, Maliki, Ja'fari, and Hanbali
        case Hanafi /// Hanafi
        
        func toInt()->Int {
            switch self {
            case Shafii: return 0
            case Hanafi: return 1
            default: return -1
            }
        }
    }
    
    enum HigherLatutudeAdjustment {
        case None
        case MidNight
        case OneSeventh
        case AngleBased
    }
    
    enum OutputTimeFormat {
        case Time24
        case Time12
        case Time12NoSuffix
        case Float
        case Date
    }
    
    enum TimeNames : Int {
        case Fajr    = 0
        case Sunrise = 1
        case Dhuhr   = 2
        case Asr     = 3
        case Sunset  = 4
        case Maghrib = 5
        case Isha    = 6
        
        func toString()->String {
            switch(self) {
            case .Fajr    : return "Fajr"
            case .Sunrise : return "Sunrise"
            case .Dhuhr   : return "Dhuhr"
            case .Asr     : return "Asr"
            case .Sunset  : return "Sunset"
            case .Maghrib : return "Maghrib"
            case .Isha    : return "Isha"
            }
        }
    }
    
    struct Coordinate {
        var latitude:Double
        var longitude:Double
        
        init(lat:Double, lng:Double){
            latitude = lat
            longitude = lng
        }
    }
    
    private static let GregorianCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    private static let DefaultDayTimes:[TimeNames: Double] = [
        TimeNames.Fajr    : 5.0,
        TimeNames.Sunrise : 6.0,
        TimeNames.Dhuhr   : 12.0,
        TimeNames.Asr     : 13.0,
        TimeNames.Sunset  : 18.0,
        TimeNames.Maghrib : 18.0,
        TimeNames.Isha    : 18.0
    ]
    
    //------------------------------------------------------
    // MARK: - Technical Settings
    //------------------------------------------------------
    
    /// number of iterations needed to compute times
    var numIterations:Int = 1
    
    /**
    `self.methodParams[methodNum] = @[fa, ms, mv, is, iv];`
    
    **Note:**
    fa : fajr angle
    ms : maghrib selector (0 = angle; 1 = minutes after sunset)
    mv : maghrib parameter value (in angle or minutes)
    is : isha selector (0 = angle; 1 = minutes after maghrib)
    iv : isha parameter value (in angle or minutes)
    `
    */
    var methodParams:[CalculationMethod: [Float]] = [
        .MWL     : [18  , 1, 0  , 0, 17  ],
        .ISNA    : [15  , 1, 0  , 0, 15  ],
        .Egypt   : [19.5, 1, 0  , 0, 17.5],
        .Makkah  : [18.5, 1, 0  , 1, 90  ],
        .Karachi : [18  , 1, 0  , 0, 18  ],
        .Tehran  : [17.7, 0, 4.5, 0, 14  ],
        .Jafari  : [16  , 0, 4  , 0, 14  ],
        .Custom  : [18  , 1, 0  , 0, 17  ]
    ];
    
    //------------------------------------------------------
    // MARK: - Properties
    //------------------------------------------------------
    
    var offsets:[TimeNames: Double] = [
        .Fajr    : 0,
        .Sunrise : 0,
        .Dhuhr   : 0,
        .Asr     : 0,
        .Sunset  : 0,
        .Maghrib : 0,
        .Isha    : 0
    ];
    
    
    // Once 'computePrayerTimes' is called,
    // computed values are stored here for reuse
    var currentPrayerTimes:[TimeNames: Double]?
    
    var calculationMethod      = CalculationMethod.MWL
    var asrJuristic            = JuristicMethod.Shafii
    var highLatitudeAdjustment = HigherLatutudeAdjustment.MidNight
    var outputFormat           = OutputTimeFormat.Time24
    
    // Not sure if it should be replaced by offsets[.Dhuhr]
    var dhuhrMinutes:Float = 0
    
    var coordinate:Coordinate! {
        didSet {
            calculateJulianDate()
        }
    }
    
    var timeZone:Float   = AKPrayerTime.systemTimeZone()
    
    var calcDate:NSDate! {
        didSet {
            calculateJulianDate()
        }
    }
    
    private lazy var jDate:Double = AKPrayerTime.julianDateFromDate(NSDate())
    
    //------------------------------------------------------
    // MARK: - Constructor
    //------------------------------------------------------
    
    init(lat:Double, lng:Double){
        coordinate = Coordinate(lat: lat, lng: lng)
        calcDate = NSDate()
    }
    
    //------------------------------------------------------
    // MARK: - Utility Methods (Type Methods)
    //------------------------------------------------------
    
    class func systemTimeZone()->Float {
        let timeZone = NSTimeZone.localTimeZone()
        return Float(timeZone.secondsFromGMT)/3600.0
    }
    
    class func dayLightSavingOffset()->Double {
        let timeZone = NSTimeZone.localTimeZone()
        return Double(timeZone.daylightSavingTimeOffsetForDate(NSDate()))
    }
    
    //------------------------------------------------------
    // MARK: - Public Methods: Get prayer times
    //------------------------------------------------------
    
    // return prayer times for a given date
    func getDatePrayerTimes(#year:Int, month:Int, day:Int, latitude:Double, longitude:Double, tZone:Float)->[TimeNames: AnyObject] {
        coordinate = Coordinate(lat: latitude, lng: longitude)
        
        //        calcYear  = year
        //        calcMonth = month
        //        calcDay   = day
        var comp = NSDateComponents()
        comp.year = year
        comp.month = month
        comp.day = day
        calcDate = AKPrayerTime.GregorianCalendar.dateFromComponents(comp)
        
        //timeZone = this.effectiveTimeZone(year, month, day, timeZone);
        //timeZone = [self getTimeZone];
        timeZone = tZone
        jDate = AKPrayerTime.julianDate(year: year, month: month, day: day)
        
        let lonDiff = longitude / (15.0 * 24.0)
        jDate = jDate - lonDiff;
        return computeDayTimes()
    }
    
    //return prayer times for a date(or today) when everything is set
    func getPrayerTimes()->[TimeNames: AnyObject]? {
        // If coordinate is not set, cannot obtain prayer times
        if coordinate == nil {
            return nil
        }
        
        // If date is not set, set today as calcDate
        if calcDate == nil {
            calcDate = NSDate()
        }
        
        // jDate should be autometically set already
        return computeDayTimes()
    }
    
    //------------------------------------------------------
    // MARK: - Public Methods: Configurations
    //------------------------------------------------------
    
    // set custom values for calculation parameters
    func setCustomParams(params:[Float]) {
        var cust = methodParams[CalculationMethod.Custom]!
        var curr = methodParams[calculationMethod]!
        for (var i=0; i<5; i++)
        {
            var j:Float = params[i];
            if j == -1 {
                cust[i] = curr[i]
            } else {
                cust[i] = j
            }
        }
        methodParams[CalculationMethod.Custom] = cust
        calculationMethod = CalculationMethod.Custom
    }
    
    // set the angle for calculating Fajr
    func setFajrAngle(angle:Float) {
        setCustomParams([angle, -1.0, -1.0, -1.0, -1.0])
    }
    
    // set the angle for calculating Maghrib
    func setMaghribAngle(angle:Float) {
        setCustomParams([-1.0, 0.0, angle, -1.0, -1.0])
    }
    
    // set the angle for calculating Isha
    func setIshaAngle(angle:Float) {
        setCustomParams([-1.0, -1.0, -1.0, 0.0, angle])
    }
    
    // set the minutes after Sunset for calculating Maghrib
    func setMaghribMinutes(minutes:Float) {
        setCustomParams([-1.0, 1.0, minutes, -1.0, -1.0])
    }
    
    // set the minutes after Maghrib for calculating Isha
    func setIshaMinutes(minutes:Float) {
        setCustomParams([-1.0, -1.0, -1.0, 1.0, minutes])
    }
    
    //------------------------------------------------------
    // MARK: - Public Methods: Format Conversion
    //------------------------------------------------------
    
    // convert double hours to (hours, minutes)
    func floatToHourMinute(time:Double)->(hours:Int, minutes:Int)? {
        if time.isNaN {
            return nil
        }
        
        var ttime = fixHour(time + 0.5 / 60.0)  // add 0.5 minutes to round
        var hours = Int(floor(time))
        var minutes = Int(floor((ttime - Double(hours)) * 60.0))
        
        return (hours: hours, minutes: minutes)
    }
    
    // convert double hours to 24h format
    func floatToTime24(time:Double)->String {
        if let (hours, minutes) = floatToHourMinute(time) {
            return NSString(format: "%02d:%02d", hours, minutes) as String
        } else {
            return "---"
        }
    }
    
    // convert double hours to 12h format
    func floatToTime12(time:Double, noSuffix:Bool)->String {
        if let (hours, minutes) = floatToHourMinute(time) {
            return NSString(format: "%02d:%02d%@", (hours % 12), minutes, (noSuffix ? "" : ((hours > 12) ? " pm" : " am")) ) as String
        } else {
            return "---"
        }
    }
    
    // convert double hours to 12h format with no suffix
    func floatToTime12NS(time:Double)->String {
        return floatToTime12(time, noSuffix: true)
    }
    
    func floatToNSDate(time:Double)->NSDate? {
        if let (hours, minutes) = floatToHourMinute(time) {
            var components = AKPrayerTime.GregorianCalendar.components(NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: calcDate)
            components.hour = hours
            components.minute = minutes
            return AKPrayerTime.GregorianCalendar.dateFromComponents(components)
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
                jDate = AKPrayerTime.julianDateFromDate(date)
                jDate = jDate - (latlng.longitude / (15.0 * 24.0))
            }
        }
    }
    
    class func julianDateFromDate(date:NSDate)->Double {
        var components = GregorianCalendar.components(NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: NSDate())
        return julianDate(year: components.year, month: components.month, day: components.day)
    }
    
    class func julianDate(#year:Int, month:Int, day:Int)->Double {
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
    private func sunPosition(jd:Double)->(Double, Double) {
        var D = jd - 2451545.0;
        var g = DMath.fixAngle(357.529 + 0.98560028 * D)
        var q = DMath.fixAngle(280.459 + 0.98564736 * D)
        var L = DMath.fixAngle(q + (1.915 * DMath.dSin(g)) + (0.020 * DMath.dSin(2 * g)))
        
        //double R = 1.00014 - 0.01671 * [self dcos:g] - 0.00014 * [self dcos: (2*g)];
        var e = 23.439 - (0.00000036 * D)
        var RA = DMath.dArcTan2(DMath.dCos(e) * DMath.dSin(L), x: DMath.dCos(L)) / 15.0
        RA = fixHour(RA);
        
        let d = DMath.dArcSin(DMath.dSin(e) * DMath.dSin(L))
        let EqT = q / 15.0 - RA;
        
        return (d, EqT);
    }
    
    // compute equation of time
    private func equationOfTime(jd:Double)->Double {
        let (_, EqT) = sunPosition(jd)
        return EqT
    }
    
    // compute declination angle of sun
    private func sunDeclination(jd:Double)->Double {
        let (d, _) = sunPosition(jd)
        return d
    }
    
    // compute mid-day (Dhuhr, Zawal) time
    private func computeMidDay(t:Double)->Double {
        let T = equationOfTime(jDate + t)
        return fixHour(12 - T)
    }
    
    // compute time for a given angle G
    private func computeTime(G:Double, t:Double)->Double {
        let D:Double = sunDeclination(jDate + t)
        let Z:Double = computeMidDay(t)
        let V:Double = DMath.dArcCos((-DMath.dSin(G) - (DMath.dSin(D) * DMath.dSin(coordinate!.latitude))) / (DMath.dCos(D) * DMath.dCos(coordinate!.latitude))) / 15.0
        
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
    private func timeDiff(time1:Double, time2:Double)->Double {
        return fixHour(time2 - time1)
    }

    //------------------------------------------------------
    // MARK: - Compute Prayer Times
    //------------------------------------------------------
    
    // compute prayer times at given julian date
    func computeTimes(times:[TimeNames: Double])->[TimeNames: Double] {
        var t = dayPortion(times)
        var params = methodParams[calculationMethod]!
        
        let idk = params[0]
        let fajr:Double    = computeTime((180.0 - Double(idk)), t: t[.Fajr]!)
        let sunrise:Double = computeTime((180.0 - 0.833), t: t[.Sunrise]!)
        let dhuhr:Double   = computeMidDay(t[.Dhuhr]!)
        let asr:Double     = computeAsr(Double(1 + asrJuristic.toInt()), t: t[.Asr]!)
        let sunset:Double  = computeTime(0.833, t: t[.Sunset]!)
        let maghrib:Double = computeTime(Double(params[2]), t: t[.Maghrib]!)
        let isha:Double    = computeTime(Double(params[4]), t: t[.Isha]!)
        
        var cTimes = [
            TimeNames.Fajr    : fajr,
            TimeNames.Sunrise : sunrise,
            TimeNames.Dhuhr   : dhuhr,
            TimeNames.Asr     : asr,
            TimeNames.Sunset  : sunset,
            TimeNames.Maghrib : maghrib,
            TimeNames.Isha    : isha
        ]
        
        //Tune times here
        //Ctimes = [self tuneTimes:Ctimes];
        
        return cTimes;
    }
    
    // compute prayer times at given julian date
    private func computeDayTimes()->[TimeNames: AnyObject] {
        //default times
        var times = AKPrayerTime.DefaultDayTimes;
        
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
    
    //Tune timings for adjustments
    //Set time offsets
    func tune(offsetTimes:[TimeNames: Double]) {
        offsets = offsetTimes;
    }
    
    func tuneTimes(times:[TimeNames: Double])->[TimeNames: Double] {
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
    func fixHour(a:Double)->Double {
        return DMath.wrap(a, min: 0, max: 24)
    }
    
    // adjust times in a prayer time array
    func adjustTimes(times:[TimeNames: Double])->[TimeNames: Double] {
        var ttimes = times
        var dTime:Double
        var dTime1:Double
        var dTime2:Double
        
        for (timeName, time) in ttimes {
            ttimes[timeName] = time + (Double(timeZone) - coordinate!.longitude / 15.0);
        }
        
        ttimes[TimeNames.Dhuhr] = ttimes[TimeNames.Dhuhr]! + (Double(dhuhrMinutes) / 60.0); //Dhuhr
        
        var params = methodParams[calculationMethod]!
        var val = params[1]
        
        if (val == 1.0) { // Maghrib
            dTime1 = ttimes[TimeNames.Sunset]! + Double(params[2] / 60.0)
            ttimes[TimeNames.Maghrib] = dTime1
        }
        
        if params[3] == 1 { // Isha
            dTime2 = ttimes[TimeNames.Maghrib]! + Double(params[4] / 60.0)
            ttimes[TimeNames.Isha] = dTime2
        }
        
        if (highLatitudeAdjustment != HigherLatutudeAdjustment.None){
            ttimes = adjustHighLatTimes(ttimes)
        }
        return ttimes;
    }
    
    // convert times array to given time format
    func adjustTimesFormat(times:[TimeNames: Double])->[TimeNames: AnyObject] {
        var ttimes:[TimeNames: AnyObject] = [TimeNames: AnyObject]()
        
        for (timeName, time) in times {
            if (outputFormat == OutputTimeFormat.Float) {
                ttimes[timeName] = time as AnyObject
            } else if (outputFormat == OutputTimeFormat.Time12) {
                ttimes[timeName] = floatToTime12(time, noSuffix: false)
            } else if (outputFormat == OutputTimeFormat.Time12NoSuffix) {
                ttimes[timeName] = floatToTime12(time, noSuffix:true)
            } else if (outputFormat == OutputTimeFormat.Time24){
                ttimes[timeName] = floatToTime24(time)
            } else {
                // floatToNSDate can return nil, if time is invalid
                ttimes[timeName] = floatToNSDate(time)
            }
        }
        return ttimes;
    }
    
    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    func adjustHighLatTimes(times:[TimeNames: Double])->[TimeNames: Double] {
        var ttimes = times
        let params = methodParams[calculationMethod]!
        
        var nightTime = timeDiff(ttimes[TimeNames.Sunset]!, time2:ttimes[TimeNames.Sunrise]!) // sunset to sunrise
        
        // Adjust Fajr
        let fajrDiff = nightPortion(Double(params[0])) * nightTime;
        if (ttimes[TimeNames.Fajr]!.isNaN || timeDiff(ttimes[TimeNames.Fajr]!, time2: ttimes[TimeNames.Sunrise]!) > fajrDiff) {
            ttimes[TimeNames.Fajr] = ttimes[TimeNames.Sunrise]! - fajrDiff
        }
        
        // Adjust Isha
        let ishaAngle:Double = (params[3] == 0.0) ? Double(params[4]) : 18.0
        let ishaDiff:Double = nightPortion(ishaAngle) * nightTime
        if (ttimes[TimeNames.Isha]!.isNaN || timeDiff(ttimes[TimeNames.Sunset]!, time2: ttimes[TimeNames.Isha]!) > ishaDiff) {
            ttimes[TimeNames.Isha] = ttimes[TimeNames.Sunset]! + ishaDiff
        }
        
        // Adjust Maghrib
        let maghribAngle:Double = (params[1] == 0.0) ? Double(params[2]) : 4.0
        let maghribDiff:Double = nightPortion(maghribAngle) * nightTime
        if (ttimes[TimeNames.Maghrib]!.isNaN || timeDiff(ttimes[TimeNames.Sunset]!, time2: ttimes[TimeNames.Maghrib]!) > maghribDiff) {
            ttimes[TimeNames.Maghrib] = ttimes[TimeNames.Sunset]! + maghribDiff
        }
        
        return ttimes;
    }
    
    // the night portion used for adjusting times in higher latitudes
    func nightPortion(angle:Double)->Double {
        var calc:Double
        
        switch highLatitudeAdjustment {
        case .None       : calc = 0.0
        case .AngleBased : calc = angle / 60.0
        case .MidNight   : calc = 0.5
        case .OneSeventh : calc = 0.14286
        }
        
        return calc;
    }
    
    // convert hours to day portions
    func dayPortion(times:[TimeNames: Double])->[TimeNames: Double] {
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
    class func wrap(a:Double, min:Double, max:Double)->Double {
        var aa = a
        let range = max - min
        aa %= range
        if aa < min { aa += range }
        if aa > max { aa -= range }
        return aa
    }
    
    // range reduce angle in degrees.
    class func fixAngle(a:Double)->Double {
        return wrap(a, min: 0, max: 360)
    }
    
    // radian to degree
    class func radiansToDegrees(alpha:Double) ->Double{
        return ((alpha*180.0)/M_PI);
    }
    
    //deree to radian
    class func degreesToRadians(alpha:Double)->Double {
        return ((alpha*M_PI)/180.0);
    }
    
    // degree sin
    class func dSin(d:Double)->Double {
        return sin(degreesToRadians(d))
    }
    
    // degree cos
    class func dCos(d:Double)->Double {
        return cos(degreesToRadians(d))
    }
    
    // degree tan
    class func dTan(d:Double)->Double {
        return tan(degreesToRadians(d))
    }
    
    // degree arcsin
    class func dArcSin(x:Double)->Double {
        let val = asin(x)
        return radiansToDegrees(val)
    }
    
    // degree arccos
    class func dArcCos(x:Double)->Double {
        let val = acos(x);
        return radiansToDegrees(val)
    }
    
    // degree arctan
    class func dArcTan(x:Double)->Double {
        let val = atan(x);
        return radiansToDegrees(val)
    }
    
    // degree arctan2
    class func dArcTan2(y:Double, x:Double)->Double {
        let val = atan2(y, x);
        return radiansToDegrees(val)
    }
    
    // degree arccot
    class func dArcCot(x:Double)->Double {
        let val = atan2(1.0, x);
        return radiansToDegrees(val)
    }
}
