//
//  StringConverter.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/15/21.
//

import Foundation

public protocol StringConverter {
    associatedtype Value
    static func string(_ value: Value) -> String
}
