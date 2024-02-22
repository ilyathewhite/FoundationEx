//
//  NSRange.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 7/5/17.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public extension NSRange {
    static var zero: NSRange = NSRange(location: 0, length: 0)
}

extension NSRange: Sequence {
    public struct Iterator: IteratorProtocol {
        var range: NSRange

        public mutating func next() -> Int? {
            if range.length == 0 {
                return nil
            }
            let value = range.location
            range.location += 1
            range.length -= 1
            return value
        }
    }
    
    public func makeIterator() -> Iterator {
        .init(range: self)
    }
}
