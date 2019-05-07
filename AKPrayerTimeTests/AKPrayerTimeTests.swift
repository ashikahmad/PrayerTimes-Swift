//
//  AKPrayerTimeTests.swift
//  AKPrayerTimeTests
//
//  Created by Ashik uddin Ahmad on 5/3/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import XCTest
import AKPrayerTime

class AKPrayerTimeTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_PrayerTimes_Doha() {
        let bundle = Bundle(for: type(of: self))
        let path = bundle
            .path(forResource: "Doha-Qatar", ofType: "json")
            .map(URL.init(fileURLWithPath:))

        let data = try? Data(contentsOf: path!)
        let json = JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary

        let params = json["params"] as! NSDictionary
        let lat = params["latitude"] as! Double
        let lon = params["longitude"] as! Double
        let zone = params["timezone"] as! String
        let timezone = TimeZone(identifier: zone)!

        let kit = AKPrayerTime(lat: lat, lng: lon)
        kit.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func parseParams(_ data: NSDictionary) -> (
        AKPrayerTime.CalculationMethod,
        AKPrayerTime.AsrJuristicMethod,
        AKPrayerTime.HigherLatutudeAdjustment)
    {
        var params: CalculationParameters!
        var calcMethod: AKPrayerTime.CalculationMethod

        let method = data["method"] as! String
        switch method {
        case "MuslimWorldLeague": calcMethod = .mwl
        case "Egyptian": calcMethod = .egypt
        case "Karachi": calcMethod = .karachi
        case "UmmAlQura": calcMethod = .makkah
//        case "Dubai": calcMethod = .tehran
//        case "MoonsightingCommittee": calcMethod = .
        case "NorthAmerica": calcMethod = .isna
//        case "Kuwait": calcMethod = .
//        case  "Qatar": calcMethod = .
//        case  "Singapore": calcMethod = .
        }



        let madhab = data["madhab"] as! String

        if madhab == "Shafi" {
            params.madhab = .shafi
        } else if madhab == "Hanafi" {
            params.madhab = .hanafi
        }

        let highLatRule = data["highLatitudeRule"] as! String

        if highLatRule == "SeventhOfTheNight" {
            params.highLatitudeRule = .seventhOfTheNight
        } else if highLatRule == "TwilightAngle" {
            params.highLatitudeRule = .twilightAngle
        } else {
            params.highLatitudeRule = .middleOfTheNight
        }

        return params
    }
}
