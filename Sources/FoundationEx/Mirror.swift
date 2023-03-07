//
//  Mirror.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation

public func codeString<T>(_ value: T, indent: Int = 0, maxWidth: Int = Int.max) -> String {
    if let strValue = value as? String {
        return "\"\(strValue)\""
    }

    let mirror = Mirror.init(reflecting: value)
    guard let displayStyle = mirror.displayStyle else {
        return String(describing: value)
    }
    var res = ""
    switch displayStyle {
    case .enum:
        if let (caseLabel, caseValue) = mirror.children.first {
            guard let caseLabel else {
                assertionFailure()
                return res
            }
            var caseValueStr = codeString(caseValue)
            if Mirror(reflecting: caseValue).displayStyle == .tuple {
                caseValueStr = String(caseValueStr.dropFirst().dropLast()) // remove the extra ()
            }
            res.append(".\(caseLabel)(\(caseValueStr))")
        }
        else {
            res = ".\(value)"
        }

    case .struct, .class:
        let name = "\(mirror.subjectType)"
        let shortName = name.split(separator: ".").last.map { String($0) } ?? name
        res.append(shortName)
        res.append("(")
        var isFirst = true
        for (propertyName, value) in mirror.children {
            guard let propertyName else {
                assertionFailure()
                return res
            }
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }
            res.append(propertyName)
            res.append(": ")
            res.append(codeString(value))
        }
        res.append(")")
        
    case .tuple:
        res.append("(")
        var isFirst = true
        for (label, value) in mirror.children {
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }
            
            if let label, !label.starts(with: ".") {
                res.append(label)
                res.append(": ")
            }
            res.append(codeString(value))
        }
        res.append(")")
        
    case .optional:
        if let (_, value) = mirror.children.first {
            res.append(codeString(value))
        }
        else {
            res.append("nil")
        }
        
    case .collection:
        res.append("[")
        var isFirst = true
        for (label, value) in mirror.children {
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }
            
            assert(label == nil)
            res.append(codeString(value))
        }
        res.append("]")
        
    case .set:
        var values: [String] = []
        for (label, value) in mirror.children {
            assert(label == nil)
            values.append(codeString(value))
        }
        values.sort()
        
        res.append("Set([")
        var isFirst = true
        for value in values {
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }

            res.append(value)
        }
        res.append("])")

    case .dictionary:
        var dict: [String: String] = [:]
        for (_, value) in mirror.children {
            let valueMirror = Mirror(reflecting: value)
            var key: String?
            var value: String?
            for  (index, (_, tupleValue)) in valueMirror.children.enumerated() {
                if index == 0 {
                    key = codeString(tupleValue)
                }
                else if index == 1 {
                    value = codeString(tupleValue)
                }
            }
            guard let key, let value else {
                assertionFailure()
                continue
            }
            dict[key] = value
        }
        
        guard !dict.isEmpty else {
            return "[:]"
        }

        res.append("[")
        var isFirst = true
        for key in dict.keys.sorted() {
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }
            guard let value = dict[key] else {
                assertionFailure()
                continue
            }
            res.append("\(key): \(value)")
        }
        res.append("]")

    default:
        return String(describing: value)
    }
    return res
}

