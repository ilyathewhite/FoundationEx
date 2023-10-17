//
//  UserDefaultsBacked.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 9/14/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public protocol DefaultsStorage: AnyObject {
    func object(forKey defaultName: String) -> Any?
    func set( _ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: DefaultsStorage {
}

public class TestDefaultsStorage: DefaultsStorage {
    private var storage: [String: Any] = [:]
    
    public init() {}
    
    public func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }
    
    public func set( _ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    public func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}

public protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    public var isNil: Bool { self == nil }
}

extension DefaultsStorage {
    public func maybeSet<T: PropertyListRepresentable>(_ value: T, forKey key: String)  {
        if let optional = value as? AnyOptional, optional.isNil {
            removeObject(forKey: key)
        }
        else {
            set(value.encode(), forKey: key)
        }
    }
}

@propertyWrapper
public struct UserDefaultsBacked<Value: PropertyListRepresentable> {
    public let key: String
    public var storage: DefaultsStorage
    public let defaultValue: Value

    var storedValue: Value {
        guard let anyValue = storage.object(forKey: key) else {
            return defaultValue
        }
        guard let encoded = anyValue as? Value.PropertyListValue else {
            assertionFailure()
            return defaultValue
        }
        return (try? Value.decode(encoded)) ?? defaultValue
    }

    public init(key: String, storage: DefaultsStorage, defaultValue: Value) {
        self.key = key
        self.storage = storage
        self.defaultValue = defaultValue
    }

    public var wrappedValue: Value {
        get {
            storedValue
        }
        set {
            storage.maybeSet(newValue, forKey: key)
        }
    }
}
