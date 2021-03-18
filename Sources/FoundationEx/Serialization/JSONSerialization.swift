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
