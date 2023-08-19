//
//  DataSerialization.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/24/17.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation
import Tagged

// MARK: - PropertyListRepresentable

public protocol PropertyListRepresentable {
    associatedtype PropertyListValue
    func encode() -> PropertyListValue
    static func decode(_: PropertyListValue) throws -> Self
}

public enum PropertyListError<T>: Error {
    case invalidType(expected: T.Type, key: String, value: Any)
    case invalidValue(value: Any, error: Error?)
    case decode(Error)
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

// MARK: - PropertyListRepresentable for basic types that require some conversion

extension Array: PropertyListRepresentable where Element: PropertyListRepresentable {
    public func encode() -> Array<Element.PropertyListValue> {
        self.map { $0.encode() }
    }
    
    public static func decode(_ plistValue: Array<Element.PropertyListValue>) throws -> Self {
        try plistValue.map { try Element.decode($0) }
    }
}

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
                PropertyListError<Self>.invalidValue(value: plistValue, error: nil)
            )
        }
    }
}

extension Tagged: PropertyListRepresentable where RawValue: PropertyListRepresentable {
    public func encode() -> RawValue.PropertyListValue {
        rawValue.encode()
    }
    public static func decode(_ encodedValue: RawValue.PropertyListValue) throws -> Self {
        try .init(RawValue.decode(encodedValue))
    }
}


extension JSONRawValue: PropertyListRepresentable {
    public func encode() -> String {
        rawValue
    }

    public static func decode(_ encodedValue: String) throws -> Self {
        guard let data = encodedValue.data(using: .utf8) else {
            throw PropertyListError<Value>.invalidValue(value: encodedValue, error: nil)
        }
        return try .init(JSONDecoder().decode(Value.self, from: data))
    }
}

extension Optional: PropertyListRepresentable where Wrapped: PropertyListRepresentable {
    public func encode() -> Wrapped.PropertyListValue? {
        self.map { $0.encode() }
    }
    public static func decode(_ encodedValue: Wrapped.PropertyListValue?) throws -> Self {
        try encodedValue.map { try Wrapped.decode($0) }
    }
}

// MARK: - PropertyListRepresentableAsJSON

public protocol PropertyListRepresentableAsJSON: PropertyListRepresentable where Self: Codable {
}

extension PropertyListRepresentableAsJSON {
    public func encode() -> String {
        JSONRawValue(self).encode()
    }

    public static func decode(_ value: String) throws -> Self {
        try JSONRawValue.decode(value).value
    }
}
