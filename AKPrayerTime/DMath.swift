//
//  DMath.swift
//  AKPrayerTime
//
//  Created by Ashik uddin Ahmad on 4/21/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import Foundation

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
        return a.reduce(max: 360) //wrap(a, min: 0, max: 360)
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
