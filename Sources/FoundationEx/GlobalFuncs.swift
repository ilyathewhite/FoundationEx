//
//  GlobalFuncs.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/14/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public func isTesting() -> Bool {
    NSClassFromString("XCTest") != nil
}

public func address(of value: AnyObject) -> String {
    "\(Unmanaged.passUnretained(value).toOpaque())"
}
