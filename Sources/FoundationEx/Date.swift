//
//  Date.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/21/17.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public extension Date {
    func isInRange(min: Date, max: Date) -> Bool {
        return (min <= self) && (self <= max)
    }

    func isInRange(_ range: (Date, Date)) -> Bool {
        return isInRange(min: range.0, max: range.1)
    }

    var timeIntervalToNow: TimeInterval {
        Date().timeIntervalSince(self)
    }
}
