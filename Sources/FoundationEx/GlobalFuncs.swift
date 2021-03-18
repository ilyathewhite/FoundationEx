//
//  GlobalFuncs.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/14/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public func maybe<T>(_ logError: (Error) -> Void = FoundationEx.env.logGeneralError, _ arg: () throws -> T) -> T? {
    do {
        return try arg()
    }
    catch {
        logError(error)
        return nil
    }
}

public func delay(_ seconds: Double, execute: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
}

public func isTesting() -> Bool {
    NSClassFromString("XCTest") != nil
}

public func address(of value: AnyObject) -> String {
    "\(Unmanaged.passUnretained(value).toOpaque())"
}
