//
//  DataSerialization.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/24/17.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public protocol RawValueRepresentable {
    associatedtype RawValue
    init?(rawValue: RawValue)
    var rawValue: RawValue { get }
}

public enum PropertyListError<T>: Error {
    case missingProperty(key: String)
    case invalidType(expected: T.Type, key: String, value: Any)
    case invalidValue(key: String, value: Any, error: Error?)
    case decode(Error)
}

public typealias PropertyListDict = [String: Any]
public typealias PropertyListArray = [Any]

public protocol AnyPropertyList {}
extension PropertyListDict: AnyPropertyList {}
extension PropertyListArray: AnyPropertyList {}
extension Optional: AnyPropertyList where Wrapped: AnyPropertyList {}

// MARK: - PropertyListRepresentable

public protocol PropertyListRepresentable {
    associatedtype PropertyListValue
    func encode() -> PropertyListValue
    static func decode(_: PropertyListValue) throws -> Self
}

// MARK: - PropertyListRepresentable as self

public protocol PropertyListRepresentableAsSelf: PropertyListRepresentable where PropertyListValue == Self {
}

extension PropertyListRepresentableAsSelf {
    public func encode() -> Self {
        self
    }

    public static func decode(_ value: Self) -> Self {
        value
    }
}

extension Int: PropertyListRepresentableAsSelf {}
extension String: PropertyListRepresentableAsSelf {}
extension Double: PropertyListRepresentableAsSelf {}
extension Bool: PropertyListRepresentableAsSelf {}
extension Date: PropertyListRepresentableAsSelf {}

// MARK: - PropertyListRepresentable as RawValue

public protocol PropertyListRepresentableAsRawValue: RawValueRepresentable, PropertyListRepresentable
where RawValue: PropertyListRepresentable, PropertyListValue == RawValue {
}

extension PropertyListRepresentableAsRawValue {
    public func encode() -> RawValue {
        rawValue
    }

    public static func decode(_ rawValue: RawValue) throws -> Self {
        if let value = Self(rawValue: rawValue) {
            return value
        }
        else {
            throw PropertyListError<Self>.decode(
                PropertyListError<Self>.invalidValue(key: "rawValue", value: rawValue, error: nil)
            )
        }
    }
}

// MARK: - PropertyListRepresentable for basic types that require some conversion

extension URL: PropertyListRepresentable {
    public func encode() -> String {
        absoluteString
    }

    public static func decode(_ plistValue: String) throws -> Self {
        if let value = URL(string: plistValue) {
            return value
        }
        else {
            throw PropertyListError<Self>.decode(
                PropertyListError<Self>.invalidValue(key: "", value: plistValue, error: nil)
            )
        }
    }
}

// MARK: - PropertyListRepresentable for container types

public extension PropertyListRepresentable {
    func encodeInContainer() -> PropertyListValue? {
        if let optional = self as? AnyOptional, optional.isNil {
            return nil
        }
        else {
            return encode()
        }
    }
}

extension Optional: PropertyListRepresentable where Wrapped: PropertyListRepresentable {
    public func encode() -> Wrapped.PropertyListValue? {
        self?.encode()
    }

    public static func decode(_ encoded: Wrapped.PropertyListValue?) throws -> Self {
        do {
            return try encoded.map(Wrapped.decode)
        }
        catch {
            throw PropertyListError<Self>.decode(error)
        }
    }
}

extension Array: PropertyListRepresentable where Element: PropertyListRepresentable {
    public func encode() -> [Element.PropertyListValue] {
        compactMap { $0.encodeInContainer() }
    }

    public static func decode(_ encodedValue: [Element.PropertyListValue]) throws -> Self {
        do {
            return try encodedValue.map { try Element.decode($0) }
        }
        catch {
            throw PropertyListError<Self>.decode(error)
        }
    }
}

extension Dictionary: PropertyListRepresentable where Key == String, Value: PropertyListRepresentable {
    public func encode() -> [Key: Value.PropertyListValue] {
        compactMapValues { $0.encodeInContainer() }
    }

    public static func decode(_ encodedValue: [Key: Value.PropertyListValue]) throws -> Self {
        do {
            return try encodedValue.mapValues { try Value.decode($0) }
        }
        catch {
            throw PropertyListError<Self>.decode(error)
        }
    }
}

// MARK: - Using PropertyListRepresentable

extension PropertyListDict {
    public func get<T: PropertyListRepresentable>(_ key: String) throws -> T {
        guard let index = index(forKey: key) else {
            throw PropertyListError<T>.missingProperty(key: key)
        }

        let dictValue = self[index].value
        guard let encoded = dictValue as? T.PropertyListValue else {
            throw PropertyListError.invalidType(expected: T.PropertyListValue.self, key: key, value: dictValue)
        }

        do {
            return try T.decode(encoded)
        }
        catch {
            throw PropertyListError<T>.invalidValue(key: key, value: dictValue, error: error)
        }
    }

    public func get<T: PropertyListRepresentable & AnyOptional>(_ key: String) throws -> T? {
        guard let index = index(forKey: key) else {
            return nil
        }

        let dictValue = self[index].value
        guard let encoded = dictValue as? T.PropertyListValue else {
            throw PropertyListError.invalidType(expected: T.PropertyListValue.self, key: key, value: dictValue)
        }

        do {
            return try T.decode(encoded)
        }
        catch {
            throw PropertyListError<T>.invalidValue(key: key, value: dictValue, error: error)
        }
    }

    public func get<T: AnyPropertyList>(_ key: String) throws -> T {
        guard let index = index(forKey: key) else {
            throw PropertyListError<T>.missingProperty(key: key)
        }

        let dictValue = self[index].value
        guard let res = dictValue as? T else {
            throw PropertyListError.invalidType(expected: T.self, key: key, value: dictValue)
        }

        return res
    }

    public func get<T: AnyPropertyList & AnyOptional>(_ key: String) throws -> T? {
        guard let index = index(forKey: key) else {
            return nil
        }

        let dictValue = self[index].value
        guard let res = dictValue as? T else {
            throw PropertyListError.invalidType(expected: T.self, key: key, value: dictValue)
        }

        return res
    }

    public mutating func set<T: PropertyListRepresentable>(_ value: T, forKey key: String) {
        guard let encoded = value.encodeInContainer() else { return }
        self[key] = encoded
    }

    public mutating func set<T: AnyPropertyList>(_ value: T, forKey key: String) {
        self[key] = value
    }
}
