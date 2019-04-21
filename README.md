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
// Default is Muslim World Legue (.mwl) method
prayerKit.calculationMethod = .karachi

// Optionally, set your preferred Asr method.
// Default is Safi'i
prayerKit.asrJuristic = .hanafi

// ... and finally, get your times
var times = prayerKit.getPrayerTimes()

// Then, you can use it as
times[.fajr].toTime12()    // 04:14 am
times[.maghrib].toTime24() // 18:22
```

# Basic configurations

Here are the most common options you may want to set to your preferrence. To understand more, I encourage you to check out the source code; specially documentation comments.

### ◉ Property - *calculationMethod*:

Option | Description
--- | ---
`.mwl` | Muslim World League
`.isna` | Islamic Society of North America
`.egypt` | Egyptian General Authority of Survey
`.makkah` | Umm al-Qura University, Makkah
`.karachi` | University if Islamic Science, Karachi
`.tehran` | Institute if Geophysics, University of Tehran
`.jafari` | Shia Ithna Ashari, Leva Research Institute, Qum
`.custom` | This option is set **autometically** when user sets custom parameters with one or more of `set***(angle:)` or `set***(minutes:)` methods

### ◉ Property - *asrJuristic*:

Option | Description
--- | ---
`.shafii` | As followed by Shafi'i, Maliki, Ja'fari, and Hanbali schools
`.hanafi` | As followed by Hanafi school

### ❖ Time Names:
The time that are currently being calculated will be found in `AKPrayerTime.TimeNames` enum. Values of that enum are: `.imsak`, `.fajr`, `.sunrise`, `.dhuhr`, `.asr`, `.sunset`, `.maghrib`, `.isha`, `.midnight` and `.qiyam`.

> More details will be added soon. Contribution to both **source** and **documentation** is most welcome!