//
//  Locked.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/21/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public final class Locked<A> {
    private let queue: DispatchQueue
    private var _value: A
    
    public init(_ value: A, queueLabel: String = "") {
        queue = DispatchQueue(label: queueLabel)
        self._value = value
    }

    public var value: A {
        get {
            return queue.sync { self._value }
        }
    }

    public func access<T>(_ transform: (inout A) -> T) -> T {
        queue.sync {
            transform(&self._value)
        }
    }
}
