![](PrayerTimes-Banner.png)


# PrayerTime-Swift
Islamic Prayer (salah) Time calculation written in swift. This prayer time calculation code is *mostly* converted from Objective C version of similar class from [praytimes.org](http://praytimes.org).

## What it Does
It calculates prayer times for any date(s) based on:

* Latitude/Longitude
* Calculation Method
* Asr Method (Shafi'i/Hanafi)
* ... and optional higher latitude adjustment

> For more information about these calculation methods and how it is obtained, check out fine document at [prayertimes.org's wiki page](http://praytimes.org/calculation)

## How to Use
Just import `AKPrayerTime.swift` in your project, and:

``` swift
// Create PrayerKit instance with your latitude/longitude
var prayerKit:AKPrayerTime = AKPrayerTime(lat: 23.810332, lng: 90.4125181)
// Optionally, set your preferred calculation method.
// Default is Muslim World Legue (MWL) method
prayerKit.calculationMethod = .Karachi
// Optionally, set your preferred Asr method.
// Default is Safi'i
prayerKit.asrJuristic = .Hanafi
// Optionally, set your output format.
// You can obviously format it later also
prayerKit.outputFormat = .Time12
// ... and finally, get your times
var times = prayerKit.getPrayerTimes()

// Then, you can use it as
times[.Fajr]    // 04:07 am
times[.Sunrise] // 05:27 am
// ...and follow included example and public methods in source for more possibilities!
```

# Basic configurations

Property | Options 
--- | ---
calculationMethod | **.MWL** ➠ Muslim World League  <br/>**.ISNA** ➠ Islamic Society of North America <br/>**.Egypt** ➠ Egyptian General Authority of Survey <br/>**.Makkah** ➠ Umm al-Qura University, Makkah <br/>**.Karachi** ➠ University of Islamic Science, Karachi <br/>**.Tehran** ➠ Institute of Geophysics, University of Tehran <br/>**.Jafari** ➠ Shia Ithna Ashari, Leva Research Institute, Qum <br/>**.Custom** ➠ Autometically set when parameters are changed manually
asrJuristic | **.Shafii** ➠ As followed by Shafi'i, Maliki, Ja'fari, and Hanbali school <br/>**.Hanafi** ➠ As followed by Hanafi school

More details will be added soon. Contribution in both **source** and **documentation** is most welcome!