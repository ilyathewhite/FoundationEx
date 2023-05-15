//
//  JSONSerialization.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/7/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public extension JSONSerialization {
    static func stringValue(for data: Data) -> String {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? "<utf8 decoding error>"
        }
        catch {
            let stringData = String(data: data, encoding: .utf8) ?? ""
            return "<json error>\nstring data:\n\(stringData)"
        }
    }
}

public struct JSONRawValue<T: Codable>: RawRepresentable {
    public typealias Value = T
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(T.self, from: data)
        else {
            return nil
        }
        value = result
    }
}

extension JSONRawValue: Equatable where T: Equatable {}
