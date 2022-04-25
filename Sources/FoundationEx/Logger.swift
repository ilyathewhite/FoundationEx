//
//  Logger.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 4/25/22.
//  Copyright © 2022 Rocket Insights. All rights reserved.
//

import Foundation
import os

@available(iOS 14.0, *)
extension Logger {
    public func error(message: String, _ error: Error) {
        var dumpStr = ""
        dump(error, to: &dumpStr)
        self.error("\(message)\n\(dumpStr)")
    }
}
