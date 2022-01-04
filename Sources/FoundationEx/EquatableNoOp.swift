//
//  EquatableNoOp.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 12/21/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

@propertyWrapper
public struct EquatableNoOp<Value>: Equatable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }
}
