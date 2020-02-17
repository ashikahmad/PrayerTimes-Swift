//
//  Foundation+Extensions.swift
//  AKPrayerTime
//
//  Created by Ashik uddin Ahmad on 5/7/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import Foundation

extension Double {
    func reduce(max: Double, min: Double = 0) -> Double {
        let range = max - min
        return self - range * floor((self - min)/range)
    }
}
