//
//  Codable.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 4/1/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation
import Tagged
#if canImport(Combine)
import Combine
#endif

public protocol CodingKeyValue: Decodable {
    static func get<K>(from container: KeyedDecodingContainer<K>, forKey: K) throws -> Self
    #if canImport(Combine)
    @available(iOS 13, OSX 10.15, *)
    static func get<D: TopLevelDecoder, Input>(using decoder: D, from input: Input) throws -> Self where D.Input == Input
    #endif
}

public extension CodingKeyValue {
    #if canImport(Combine)
    @available(iOS 13, OSX 10.15, *)
    static func get<D: TopLevelDecoder, Input>(using decoder: D, from input: Input) throws -> Self where D.Input == Input {
        return try decoder.decode(Self.self, from: input)
    }
    #endif
}

struct ArrayContainer<T: CodingKeyValue>: CodingKeyValue {
    let wrappedValue: [T]

    init(from decoder: Decoder) throws {
        wrappedValue = try [T](from: decoder)
    }
}

private func noKeyError<K>(in container: KeyedDecodingContainer<K>, forKey key: K) -> DecodingError {
    DecodingError.keyNotFound(key, DecodingError.Context(codingPath: container.codingPath, debugDescription: ""))
}

private func noValueError<K, T>(in container: KeyedDecodingContainer<K>, forKey key: K, as type: T.Type) -> DecodingError {
    DecodingError.valueNotFound(
        type,
        DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "No value for \(key.stringValue), expected: \(type)"
        )
    )
}

extension CodingKeyValue {
    fileprivate static func conversionError<K>(in container: KeyedDecodingContainer<K>, forKey key: K) -> DecodingError {
        DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Couldn't convert JSON value to \(Self.self)"
        )
    }

    fileprivate static func conversionError(in container: UnkeyedDecodingContainer) -> DecodingError {
        DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Couldn't convert JSON value to \(Self.self)"
        )
    }

    public static func get<K>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self {
        guard container.contains(key) else {
            throw noKeyError(in: container, forKey: key)
        }

        return try container.decode(Self.self, forKey: key)
    }
}

extension URL: CodingKeyValue {}

extension Int: CodingKeyValue {
    public static func get<K>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self {
        try container.ensureNotNull(forKey: key, expected: Self.self)

        if let int = try? container.decode(Int.self, forKey: key) {
            return int
        }
        else if let string = try? container.decode(String.self, forKey: key), let int = Int(string) {
            return int
        }
        else {
            throw conversionError(in: container, forKey: key)
        }
    }
}

extension Double: CodingKeyValue {
    public static func get<K>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self {
        try container.ensureNotNull(forKey: key, expected: Self.self)

        if let double = try? container.decode(Double.self, forKey: key) {
            return double
        }
        else if let int = try? container.decode(Int.self, forKey: key) {
            return Double(int)
        }
        else if let string = try? container.decode(String.self, forKey: key), let double = Double(string) {
            return double
        }
        else {
            throw conversionError(in: container, forKey: key)
        }
    }
}

extension String: CodingKeyValue {
    public static func get<K>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self {
        try container.ensureNotNull(forKey: key, expected: Self.self)

        if let string = try? container.decode(String.self, forKey: key) {
            return string
        }
        else if let int = try? container.decode(Int.self, forKey: key) {
            return String(int)
        }
        else if let double = try? container.decode(Double.self, forKey: key) {
            return String(double)
        }
        else {
            throw conversionError(in: container, forKey: key)
        }
    }
}

extension Bool: CodingKeyValue {
    public static func get<K>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self {
        try container.ensureNotNull(forKey: key, expected: Self.self)

        if let bool = try? container.decode(Bool.self, forKey: key) {
            return bool
        }
        else if let int = try? container.decode(Int.self, forKey: key) {
            return int != 0
        }
        else if let string = try? container.decode(String.self, forKey: key) {
            switch string.lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default:
                throw conversionError(in: container, forKey: key)
            }
        }
        else {
            throw conversionError(in: container, forKey: key)
        }
    }
}

extension Tagged: CodingKeyValue where RawValue: CodingKeyValue {}

extension Array: CodingKeyValue where Element: CodingKeyValue {
    public static func get<K>(from container: KeyedDecodingContainer<K>, forKey key: K) throws -> Self {
        try container.ensureNotNull(forKey: key, expected: Self.self)
        let arrayContainer: UnkeyedDecodingContainer = try container.getNested(forKey: key)
        do {
            return try get(from: arrayContainer)
        }
        catch {
            throw conversionError(in: container, forKey: key)
        }
    }

    public static func get(from containerArg: UnkeyedDecodingContainer) throws -> Self {
        var container = containerArg
        guard let count = container.count else {
            throw conversionError(in: container)
        }
        var res: Self = []
        res.reserveCapacity(count)
        for _ in 0..<count {
            do {
                try res.append(container.decode(Element.self))
            }
            catch {
                if !FoundationEx.env.ignoreArrayContentCodingErrors {
                    throw error
                }
            }
        }
        return res
    }

    public init(from decoder: Decoder) throws {
        self = try Self.get(from: decoder.unkeyedContainer())
    }

    #if canImport(Combine)
    @available(iOS 13, OSX 10.15, *)
    public static func get<D: TopLevelDecoder, Input>(using decoder: D, from input: Input) throws -> Self where D.Input == Input {
        let valueContainer = try ArrayContainer<Element>.get(using: decoder, from: input)
        return valueContainer.wrappedValue
    }
    #endif
}

extension KeyedDecodingContainer {
    func ensureNotNull<T>(forKey key: Key, expected type: T.Type) throws {
        guard contains(key) else {
            throw noKeyError(in: self, forKey: key)
        }
        guard !((try? decodeNil(forKey: key)) ?? false) else {
            throw noValueError(in: self, forKey: key, as: type)
        }
    }

    public func isNull(forKey key: Key) throws -> Bool {
        try !contains(key) || decodeNil(forKey: key)
    }

    public func get<T: CodingKeyValue>(_ key: Key) throws -> T {
        try T.get(from: self, forKey: key)
    }

    public func get<T: CodingKeyValue>(_ key: Key) throws -> T? {
        guard try !isNull(forKey: key) else { return nil }
        return try get(key) as T
    }

    public func getNested<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
    {
        try ensureNotNull(forKey: key, expected: KeyedDecodingContainer<NestedKey>.self)
        return try nestedContainer(keyedBy: type, forKey: key)
    }

    public func getNested(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try ensureNotNull(forKey: key, expected: UnkeyedDecodingContainer.self)
        return try nestedUnkeyedContainer(forKey: key)
    }
}
