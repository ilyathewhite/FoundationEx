//
//  HexColor.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/26/21.
//

import Foundation
import CoreGraphics

extension String {
    public func parseAsHexColor() throws -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        enum ParseHexError: Error {
            case mustStartWithHash
            case invalidCharCount
            case invalidComponentFormat
            case invalidArgs
        }

        func getComponent(_ remaining: Substring) throws -> (CGFloat, Substring) {
            let componentHex = remaining.prefix(2)
            guard componentHex.count == 2 else {
                throw ParseHexError.invalidComponentFormat
            }
            guard let value = Int(componentHex, radix: 16) else {
                throw ParseHexError.invalidComponentFormat
            }
            return (CGFloat(value) / 255.0, remaining.dropFirst(2))
        }

        guard self.count >= 6 else {
            throw ParseHexError.invalidCharCount
        }

        var remaining = self[...]
        if remaining.starts(with: "#") {
            remaining = remaining.dropFirst()
        }

        var red, green, blue, opacity: CGFloat
        (red, remaining) = try getComponent(remaining)
        (green, remaining) = try getComponent(remaining)
        (blue, remaining) = try getComponent(remaining)
        if remaining.isEmpty {
            opacity = 1
        }
        else {
            (opacity, remaining) = try getComponent(remaining)
            guard remaining.isEmpty else {
                throw ParseHexError.invalidComponentFormat
            }
        }

        return (red, green, blue, opacity)
    }
}
