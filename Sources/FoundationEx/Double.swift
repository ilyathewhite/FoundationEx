//
//  Double.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/17/17.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public extension Double {
    var metersToMiles: Double {
        return self * (1.0 / 1609.344) // 1 Mile = 1609.344 Meters
    }
    
    var yearsToSeconds: TimeInterval {
        return self * 365.2425 * 24 * 60 * 60 // 1 Gregorian year contains 365.2425 days
    }
    
    var secondsToHours: TimeInterval {
        return self / 3600
    }
}
