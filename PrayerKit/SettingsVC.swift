//
//  SettingsVC.swift
//  PrayerKit
//
//  Created by Ashik uddin Ahmad on 4/27/19.
//  Copyright © 2019 WNeeds. All rights reserved.
//

import UIKit
import Eureka
import CoreLocation
import AKPrayerTime

protocol SettingsVCDelegate: class {
    func applyConfig()
}

class SettingsVC: FormViewController {

    let coder = CLGeocoder()
    var delegate: SettingsVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        let c = Config.global

        form
            +++ Section("Location")
            <<< LocationRow() {
                $0.title = "Coordinate"
                $0.value = c.coordinate.clLocation
                $0.onChange { [weak self] cell in
                    if let loc = cell.value {
                        self?.setLocation(loc)
                    }
                }
            }
            <<< TextRow("addr") {
                $0.title = "Address"
                $0.value = Config.global.address
                $0.disabled = true
            }
            <<< TextRow("tz") {
                $0.title = "GMT Offset"
                $0.value = String(describing: Config.global.gmtOffset)
                $0.disabled = true
            }

            +++ Section("Calculation")
            <<< ActionSheetRow<CalculationMethod>() {
                $0.title = "Calculation Method"
                $0.displayValueFor = { c in c.map { String(describing: $0).capitalized }}
                $0.options = [.mwl, .isna, .egypt, .makkah, .karachi, .tehran, .jafari]
                $0.value = Config.global.calcMethod
                $0.onChange {
                    if let value = $0.value {
                        Config.global.calcMethod = value
                    }
                }
            }
            <<< ActionSheetRow<AsrJuristicMethod>() {
                $0.title = "Asr Method"
                $0.displayValueFor = { c in c.map { String(describing: $0).capitalized }}
                $0.options = [.shafii, .hanafi]
                $0.value = Config.global.asrMethod
                $0.onChange {
                    if let value = $0.value {
                        Config.global.asrMethod = value
                    }
                }
            }
            <<< ActionSheetRow<MidnightMethod>() {
                $0.title = "Midnight Method"
                $0.displayValueFor = { c in c.map { String(describing: $0).capitalized }}
                $0.options = [.standard, .jafari]
                $0.value = Config.global.midnight
                $0.onChange {
                    if let value = $0.value {
                        Config.global.midnight = value
                    }
                }
            }
            <<< ActionSheetRow<HigherLatutudeAdjustment>() {
                $0.title = "Higher Latutude Adjustment"
                $0.displayValueFor = { c in c.map { String(describing: $0).capitalized }}
                $0.options = [.angleBased, .oneSeventh, .midNight, .none]
                $0.value = Config.global.highLat
                $0.onChange {
                    if let value = $0.value {
                        Config.global.highLat = value
                    }
                }
            }

            +++ Section()
            <<< ButtonRow() {
                $0.title = "APPLY"
                $0.onCellSelection { [weak self] _,_  in
                    print(self?.form.values() as Any)
                    self?.applyConfig()
                }
            }
    }

    func setLocation(_ loc: CLLocation) {
        Config.global.coordinate = loc.prayerLocation
        coder.reverseGeocodeLocation(loc, completionHandler: { [weak self] (placemarks, error) in
            if let place = placemarks?.first {
                let addr = self?.form.rowBy(tag: "addr") as? TextRow
                Config.global.address = place.administrativeArea
                addr?.value = Config.global.address
                addr?.updateCell()

                if let t = place.timeZone {
                    let tz = self?.form.rowBy(tag: "tz") as? TextRow
                    Config.global.gmtOffset = t.inHours()
                    tz?.value = String(describing: Config.global.gmtOffset)
                    tz?.updateCell()
                }
            }
        })
    }

    func applyConfig() {
        delegate?.applyConfig()
        navigationController?.popViewController(animated: true)
    }
}

extension TimeZone {
    func inHours() -> Float {
        return Float(secondsFromGMT())/3600.0
    }
}

extension CLLocation {
    var prayerLocation: Coordinate {
        return Coordinate(lat: coordinate.latitude, lng: coordinate.longitude)
    }
}

extension Coordinate {
    var clLocation: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}
