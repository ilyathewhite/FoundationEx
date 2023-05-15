//
//  Mirror.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation

public let codeStringDefaultMaxWidth = 50

public struct CodePropertyValuePair: Equatable, Codable, Identifiable {
    public let property: String
    public let value: String
    
    public var id: String {
        property
    }
    
    public init(property: String, value: String) {
        self.property = property
        self.value = value
    }
}

public func propertyCodeStrings<T>(_ value: T,  maxValueWidth: Int = codeStringDefaultMaxWidth) -> [CodePropertyValuePair] {
    let mirror = Mirror(reflecting: value)
    var res: [CodePropertyValuePair] = []
    switch mirror.displayStyle {
    case .class, .struct:
        for (propertyName, value) in mirror.children {
            guard let propertyName else {
                assertionFailure()
                continue
            }
            let strValue = (value as? String) ?? codeString(value, maxValueWidth: maxValueWidth)
            res.append(.init(property: propertyName, value: strValue))
        }
        return res
        
    default:
        return []
    }
}

public func singleLineCodeString<T>(_ value: T, indent: Int = 3, maxValueWidth: Int = codeStringDefaultMaxWidth) -> String {
    codeStringImpl(value, delimiter: " ", offset: 0, indent: indent, maxValueWidth: maxValueWidth)
}

public func codeString<T>(_ value: T, offset: Int = 0, indent: Int = 3, maxValueWidth: Int = codeStringDefaultMaxWidth) -> String {
    codeStringImpl(value, delimiter: "\n", offset: offset, indent: indent, maxValueWidth: maxValueWidth)
}

private func codeStringImpl<T>(_ value: T, delimiter: Character, offset: Int, indent: Int, maxValueWidth: Int) -> String {
    let forceSingleLine = (delimiter == " ")
    let mirror = Mirror(reflecting: value)

    if mirror.displayStyle != .optional {
        if value is any ExpressibleByBooleanLiteral {
            return String(describing: value)
        }
        
        if value is any ExpressibleByIntegerLiteral {
            return String(describing: value)
        }
        
        if value is any ExpressibleByFloatLiteral {
            return String(describing: value)
        }
        
        if value is any ExpressibleByStringLiteral {
            let str = String(describing: value)
            var res = ""
            res.append("\"")
            for char in str {
                if char == "\0" {
                    res.append("\\")
                    res.append("0")
                }
                else if char == "\\" {
                    res.append("\\")
                    res.append("\\")
                }
                else if char == "\t" {
                    res.append("\\")
                    res.append("t")
                }
                else if char == "\n" {
                    res.append("\\")
                    res.append("n")
                }
                else if char == "\r" {
                    res.append("\\")
                    res.append("r")
                }
                else if char == "\"" {
                    res.append("\\")
                    res.append("\"")
                }
                else if char == "\'" {
                    res.append("\\")
                    res.append("'")
                }
                else {
                    res.append(char)
                }
            }
            res.append("\"")
            return res
        }
    }
    
    func nestedCodeString<U>(_ value: U, offset: Int) -> String {
        codeStringImpl(value, delimiter: delimiter, offset: offset, indent: indent, maxValueWidth: maxValueWidth)
    }
    
    func indentString(offset: Int) -> String {
        guard !forceSingleLine else { return "" }
        return String(repeating: " ", count: offset)
    }
    
    if !forceSingleLine {
        let singleLine = singleLineCodeString(value)
        if (singleLine.count <= maxValueWidth) || forceSingleLine {
            return singleLine
        }
    }
    
    var res = ""
    
    func addNestedContent(_ nestedContent: String) -> Bool {
        guard (nestedContent.count <= maxValueWidth) || forceSingleLine else { return false }
        res.append(indentString(offset: offset + indent))
        res.append(nestedContent)
        if !forceSingleLine {
            res.append("\n")
        }
        return true
    }
    
    switch mirror.displayStyle {
    case .enum:
        if let (caseLabel, caseValue) = mirror.children.first {
            guard let caseLabel else {
                assertionFailure()
                return res
            }
            var caseValueStr = singleLineCodeString(caseValue)
            if Mirror(reflecting: caseValue).displayStyle == .tuple {
                caseValueStr = String(caseValueStr.dropFirst().dropLast()) // remove the extra ()
            }
            let savedRes = res
            res.append(".\(caseLabel)(\(caseValueStr))")
            if (res.count > maxValueWidth) && !forceSingleLine {
                res = savedRes
                let nestedOffset = offset + indent
                if caseValueStr.count <= maxValueWidth {
                    res.append(".\(caseLabel)(\n")
                    res.append(indentString(offset: nestedOffset))
                    res.append(caseValueStr)
                    res.append("\n")
                    res.append(indentString(offset: offset))
                    res.append(")")
                }
                else {
                    res.append(".\(caseLabel)(")
                    let caseValueMirror = Mirror(reflecting: caseValue)
                    switch caseValueMirror.displayStyle {
                    case .tuple:
                        // skip the extra () by iterating over the content directly
                        res.append("\n")
                        let nestedOffsetStr = indentString(offset: nestedOffset)
                        var isFirst = true
                        for (label, value) in caseValueMirror.children {
                            if !isFirst {
                                res.append(",\n")
                            }
                            else {
                                isFirst = false
                            }
                            
                            res.append(nestedOffsetStr)
                            if let label, !label.starts(with: ".") {
                                res.append(label)
                                res.append(": ")
                            }
                            res.append(nestedCodeString(value, offset: nestedOffset))
                        }
                        res.append("\n")
                        res.append(indentString(offset: offset))
                        res.append(")")
                        
                    case .collection, .set, .dictionary:
                        res.append(nestedCodeString(caseValue, offset: offset))
                        res.append(")")
                        
                    default:
                        let nestedOffsetStr = indentString(offset: nestedOffset)
                        res.append("\n")
                        res.append(nestedOffsetStr)
                        res.append(nestedCodeString(caseValue, offset: nestedOffset))
                        res.append("\n")
                        res.append(indentString(offset: offset))
                        res.append(")")                        
                    }
                }
            }
        }
        else if value is CustomStringConvertible {
            res = codeString(String(describing: value))
            if !(value is any ExpressibleByStringLiteral) {
                print("codeString(): type \(mirror.subjectType) should implement ExpressibleByStringLiteral.")
            }
        }
        else {
            res = ".\(value)"
        }

   case .tuple:
        res.append("(")
        if !forceSingleLine {
            res.append("\n")
        }
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for (label, value) in mirror.children {
            if !isFirst {
                res.append(",\(delimiter)")
            }
            else {
                isFirst = false
            }
            
            res.append(nestedOffsetStr)
            if let label, !label.starts(with: ".") {
                res.append(label)
                res.append(": ")
            }
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        if !forceSingleLine {
            res.append("\n")
            res.append(indentString(offset: offset))
        }
        res.append(")")
        
    case .optional:
        if let (_, value) = mirror.children.first {
            res.append(nestedCodeString(value, offset: offset))
        }
        else {
            res.append("nil")
        }
        
    case .collection:
        res.append("[")
        if !forceSingleLine {
            res.append("\n")
        }
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for (label, value) in mirror.children {
            if !isFirst {
                res.append(",\(delimiter)")
            }
            else {
                isFirst = false
            }
            
            assert(label == nil)
            res.append(nestedOffsetStr)
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        if !forceSingleLine {
            res.append("\n")
            res.append(indentString(offset: offset))
        }
        res.append("]")

    case .set:
        var valuesDict: [String: Any] = [:]
        for (label, value) in mirror.children {
            assert(label == nil)
            valuesDict[singleLineCodeString(value)] = value
        }
        
        res.append("Set([")
        if !forceSingleLine {
            res.append("\n")
        }
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for key in valuesDict.keys.sorted() {
            guard let value = valuesDict[key] else {
                assertionFailure()
                continue
            }
            
            if !isFirst {
                res.append(",\(delimiter)")
            }
            else {
                isFirst = false
            }

            res.append(nestedOffsetStr)
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        if !forceSingleLine {
            res.append("\n")
            res.append(indentString(offset: offset))
        }
        res.append("])")

    case .dictionary:
        var dict: [String: Any] = [:]
        for (_, value) in mirror.children {
            let valueMirror = Mirror(reflecting: value)
            var key: String?
            var value: Any?
            for  (index, (_, tupleValue)) in valueMirror.children.enumerated() {
                if index == 0 {
                    key = singleLineCodeString(tupleValue)
                }
                else if index == 1 {
                    value = tupleValue
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
        if !forceSingleLine {
            res.append("\n")
        }
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for key in dict.keys.sorted() {
            guard let value = dict[key] else {
                assertionFailure()
                continue
            }

            if !isFirst {
                res.append(",\(delimiter)")
            }
            else {
                isFirst = false
            }
            res.append(nestedOffsetStr)
            res.append("\(key): ")
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        if !forceSingleLine {
            res.append("\n")
            res.append(indentString(offset: offset))
        }
        res.append("]")

    default: // struct, class, and unknown
        let name = "\(mirror.subjectType)"
        let shortName = shortName(name)
        res.append(shortName)
        res.append("(")
        if !forceSingleLine {
            res.append("\n")
        }
        let nestedOffset = offset + indent
        var didAddAsOneLine: Bool
        do {
            var nestedContent = ""
            var isFirst = true
            for (propertyName, value) in mirror.children {
                guard let propertyName else {
                    assertionFailure()
                    continue
                }
                if !isFirst {
                    nestedContent.append(", ")
                }
                else {
                    isFirst = false
                }
                nestedContent.append(propertyName)
                nestedContent.append(": ")
                nestedContent.append(singleLineCodeString(value))
                
                if nestedContent.count > maxValueWidth {
                    break
                }
            }
            didAddAsOneLine = addNestedContent(nestedContent)
        }
        
        if !didAddAsOneLine {
            let nestedOffsetStr = indentString(offset: nestedOffset)
            var isFirst = true
            for (propertyName, value) in mirror.children {
                guard let propertyName else {
                    assertionFailure()
                    return res
                }
                if !isFirst {
                    res.append(",\n")
                }
                else {
                    isFirst = false
                }
                
                res.append(nestedOffsetStr)
                res.append(propertyName)
                res.append(": ")
                res.append(nestedCodeString(value, offset: nestedOffset))
            }
            res.append("\n")
        }
        res.append(indentString(offset: offset))
        res.append(")")
     }
    return res
}

private func shortName(_ name: String) -> String {
    name.split(separator: ".").last.map { String($0) } ?? name
}
