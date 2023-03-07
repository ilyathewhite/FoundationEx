//
//  Mirror.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation

public func codeString<T>(_ value: T) -> String {
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
        
    case .collection, .set:
        res.append(displayStyle == .set ? "Set([" : "[")
        var isFirst = true
        for (label, value) in mirror.children {
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }
            
            if let label {
                res.append(codeString(label))
                res.append(": ")
            }
            res.append(codeString(value))
        }
        res.append(displayStyle == .set ? "])" : "]")
        
    case .dictionary:
        res.append("[")
        var isFirst = true
        for (_, value) in mirror.children {
            if !isFirst {
                res.append(", ")
            }
            else {
                isFirst = false
            }
            let valueMirror = Mirror(reflecting: value)
            for  (index, (_, tupleValue)) in valueMirror.children.enumerated() {
                if index == 0 {
                    res.append(codeString(tupleValue))
                    res.append(": ")
                }
                else if index == 1 {
                    res.append(codeString(tupleValue))
                }
            }
        }
        res.append(displayStyle == .set ? "])" : "]")


    default:
        return String(describing: value)
    }
    return res
}

