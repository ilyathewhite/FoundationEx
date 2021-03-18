//
//  UserDefaultsBacked.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 9/14/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

// MARK: - UserDefaults property wrappers

public protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    public var isNil: Bool { self == nil }
}

extension UserDefaults {
    public func maybeSet<T: PropertyListRepresentable>(_ value: T, forKey key: String)  {
        if let optional = value as? AnyOptional, optional.isNil {
            removeObject(forKey: key)
        }
        else {
            set(value.encode(), forKey: key)
        }
    }
}

@propertyWrapper public struct UserDefaultsBacked<Value: PropertyListRepresentable> {
    public let key: String
    public let requireMainThread: Bool
    public var storage: UserDefaults
    public let defaultValue: Value
    public var lastValue: Value!

    var storedValue: Value {
        guard let anyValue = storage.object(forKey: key) else {
            return defaultValue
        }
        guard let encoded = anyValue as? Value.PropertyListValue else {
            assertionFailure()
            return defaultValue
        }
        return maybe(FoundationEx.env.logCodingError) { try Value.decode(encoded) } ?? defaultValue
    }

    public init(
        key: String,
        requireMainThread: Bool = true,
        storage: UserDefaults = FoundationEx.env.userDefaults,
        defaultValue: Value
    ) {
        self.key = key
        self.requireMainThread = requireMainThread
        self.storage = storage
        self.defaultValue = defaultValue
        lastValue = requireMainThread ? storedValue : defaultValue
    }

    public var wrappedValue: Value {
        get {
            requireMainThread ? lastValue : storedValue
        }
        set {
            if requireMainThread {
                assert(Thread.isMainThread)
                lastValue = newValue
            }
            storage.maybeSet(newValue, forKey: key)
        }
    }
}

public extension UserDefaultsBacked {
    init<T>(key: String, requireMainThread: Bool = true) where T? == Value {
        self = .init(key: key, requireMainThread: requireMainThread, defaultValue: nil)
    }

    init<T>(key: String, requireMainThread: Bool = true) where [T] == Value {
        self = .init(key: key, requireMainThread: requireMainThread, defaultValue: [])
    }
}
