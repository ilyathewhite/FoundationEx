//
//  Dictionary.swift
//
//  Created by Ilya Belenkiy on 4/12/23.
//

import Foundation

public extension Dictionary {
    @discardableResult
    mutating func insert(key: Key, value: Value) -> (Bool, Value) {
        if let oldValue = self[key] {
            return (false, oldValue)
        }
        else {
            self[key] = value
            return (true, value)
        }
    }
}
