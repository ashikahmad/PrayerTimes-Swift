//
//  MasterViewController.swift
//  PrayerKit
//
//  Created by Ashik Ahmad on 4/14/15.
//  Copyright (c) 2015 WNeeds. All rights reserved.
//

import UIKit
import AKPrayerTime

class MasterVC: UITableViewController {

    var todayTimes:[(PrayerName, Time)] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateTimes()
    }

    func updateTimes() {
        let prayerKit:AKPrayerTime = AKPrayerTime(
            lat: Config.global.coordinate.latitude,
            lng: Config.global.coordinate.longitude)
        prayerKit.calculationMethod = Config.global.calcMethod
        prayerKit.asrJuristic = Config.global.asrMethod
         prayerKit.timeZone = Config.global.gmtOffset
        prayerKit.highLatitudeAdjustment = Config.global.highLat
        prayerKit.setMidnightMethod(Config.global.midnight)

        let times = prayerKit.getPrayerTimes()
        if let t = times {
            todayTimes = prayerKit.sorted(t)
            tableView.reloadData()
            for (pName, time) in todayTimes {
                let paddedName:String = (pName.toString() as NSString).padding(toLength: 15, withPad: " ", startingAt: 0)
                print(paddedName  + " : \(time.toTime24())")
            }
        }

        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
        lbl.autoresizingMask = [.flexibleWidth]
        lbl.font = UIFont.boldSystemFont(ofSize: 12)
        lbl.textAlignment = .center
        lbl.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
        lbl.text = [Config.global.address, "TimeZone \(Config.global.gmtOffset)"]
            .compactMap { $0 }
            .joined(separator: " | ")
        tableView.tableHeaderView = lbl
    }

    @IBAction func gotoSettings(_ sender: Any) {
        let vc = SettingsVC()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todayTimes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let (timeName, time) = todayTimes[indexPath.row]
        cell.textLabel!.text = timeName.toString()
        cell.detailTextLabel!.text = time.toTime12()
        return cell
    }
    
}

extension MasterVC: SettingsVCDelegate {
    func applyConfig() {
        updateTimes()
    }
}
