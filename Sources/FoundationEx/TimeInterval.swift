//
//  TimeInterval.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 1/30/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public extension TimeInterval {
    static func minutes(_ value: Int) -> TimeInterval {
        60.0 * Double(value)
    }

    static func hours(_ value: Int) -> TimeInterval {
        3600.0 * Double(value)
    }

    static func days(_ value: Int) -> TimeInterval {
        86400.0 * Double(value)
    }
}
