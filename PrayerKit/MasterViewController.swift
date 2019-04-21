//
//  MasterViewController.swift
//  PrayerKit
//
//  Created by Ashik Ahmad on 4/14/15.
//  Copyright (c) 2015 WNeeds. All rights reserved.
//

import UIKit
import AKPrayerTime

class MasterViewController: UITableViewController {

    var todayTimes:[(AKPrayerTime.TimeNames, AKPrayerTime.Time)] = []

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
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        // ================================================
        // Test Values
        // ------------------------------------------------
        // (lat: 23.810332, lng: 90.4125181)    ~~> tz: +6
        // (lat: 43.6605, lng: -79.4633)        ~~> tz: -5
        // ================================================
        let prayerKit:AKPrayerTime = AKPrayerTime(lat: 23.810332, lng: 90.4125181)
        prayerKit.calculationMethod = .karachi
        prayerKit.asrJuristic = .hanafi
        // prayerKit.timeZone = -5.0
        prayerKit.setMidnightMethod(.jafari)
        let times = prayerKit.getPrayerTimes()
        if let t = times {
            todayTimes = prayerKit.sorted(t)
            tableView.reloadData()
            for (pName, time) in todayTimes {
                let paddedName:String = (pName.toString() as NSString).padding(toLength: 15, withPad: " ", startingAt: 0)
                print(paddedName  + " : \(time.toTime24())")
            }
        }
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
