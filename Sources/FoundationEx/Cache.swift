//
//  Cache.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 2/20/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public final class Cache<Key: Hashable, Value> {
    private final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) {
            self.key = key
        }

        override var hash: Int {
            key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }

    private final class WrappedValue {
        let value: Value

        init(_ value: Value) {
            self.value = value
        }
    }

    private let cache = NSCache<WrappedKey, WrappedValue>()

    public init() {}

    public func insert(_ value: Value, forKey key: Key) {
        cache.setObject(.init(value), forKey: .init(key))
    }

    public func value(forKey key: Key) -> Value? {
        cache.object(forKey: .init(key))?.value
    }

    public func removeValue(forKey key: Key) {
        cache.removeObject(forKey: .init(key))
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    public subscript(key: Key) -> Value? {
        get {
            value(forKey: key)
        }
        set {
            guard let value = newValue else {
                removeValue(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}
