//
//  DefaultsValue.swift
//  ChordMate
//
//  Created by Ilya Belenkiy on 9/14/22.
//

import Foundation

extension Int: DefaultsRawVAlue {}
extension Bool: DefaultsRawVAlue {}
extension String: DefaultsRawVAlue {}
extension Data: DefaultsRawVAlue {}

public protocol DefaultsValue: Equatable {
    associatedtype RawDefaultsValue
    var rawDefaultsValue: RawDefaultsValue? { get }
    static func defaultsValue(_ rawValue: RawDefaultsValue) -> Self?
}

public extension DefaultsValue {
    static func defaultsValue(_ rawValue: RawDefaultsValue?) -> Self? {
        return rawValue.flatMap { defaultsValue($0) }
    }
}

public protocol DefaultsRawVAlue: DefaultsValue where RawDefaultsValue == Self {
}

public extension DefaultsRawVAlue {
    var rawDefaultsValue: Self? {
        self
    }
    
    static func defaultsValue(_ rawValue: RawDefaultsValue) -> Self? {
        return rawValue
    }
}

public protocol DefaultsJSONValue: DefaultsValue, Codable where RawDefaultsValue == Data {
}

public extension DefaultsJSONValue {
    var rawDefaultsValue: Data? {
        maybe { try JSONEncoder().encode(self) }
    }
    
    static func defaultsValue(_ rawValue: Data) -> Self? {
        maybe { try JSONDecoder().decode(Self.self, from: rawValue) }
    }
}

public extension UserDefaults {
    func decode<T: DefaultsValue>(_ key: String) -> T? {
        guard let rawValue = value(forKey: key) as? T.RawDefaultsValue else { return nil }
        return T.defaultsValue(rawValue)
    }
    
    func encode<T: DefaultsValue>(_ value: T, forKey key: String) {
        let savedValue: T? = decode(key)
        if value != savedValue {
            set(value.rawDefaultsValue, forKey: key)
        }
    }
}
