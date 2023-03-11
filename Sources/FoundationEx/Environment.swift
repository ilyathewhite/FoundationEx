//
//  Environment.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 3/18/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public enum FoundationEx {
    public struct Environment {
        public var logGeneralError: (Error) -> Void
        public var logErrorMessage: (String) -> Void
        public var logCodingError: (Error) -> Void
        public var userDefaults: UserDefaults
        public var ignoreArrayContentCodingErrors = false
    }

    private static func logError(_ error: Error) {
        var errorDump = "FoundationEx Coding Error:\n"
        dump(error, to: &errorDump)
        NSLog(errorDump)
    }

    public static var env = Environment(
        logGeneralError: logError(_:),
        logErrorMessage: { NSLog($0) },
        logCodingError: logError(_:),
        userDefaults: UserDefaults.standard
    )
}
