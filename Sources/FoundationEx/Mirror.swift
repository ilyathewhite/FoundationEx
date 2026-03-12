//
//  Mirror.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public let codeStringDefaultMaxWidth = 50
public let codeStringDefaultMaxNestingLevel = 8

public protocol CustomCodeStringConvertible {
    func codeStringDescription(offset: Int, indent: Int, maxValueWidth: Int) -> String
}

public func caseName<T>(_ value: T) -> String {
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .enum:
        if let (caseLabel, _) = mirror.children.first {
            return caseLabel ?? ""
        }
        else {
            return "\(value)"
        }

    default:
        return ""
    }
}

public struct CodePropertyValuePair: Equatable, Codable, Identifiable, Sendable {
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

private struct CodeStringContext {
    let nestingLevel: Int
    let maxNestingLevel: Int
    let ancestorObjectIDs: Set<ObjectIdentifier>

    static func root(maxNestingLevel: Int) -> Self {
        .init(
            nestingLevel: 0,
            maxNestingLevel: max(0, maxNestingLevel),
            ancestorObjectIDs: []
        )
    }

    func descended() -> Self {
        .init(
            nestingLevel: nestingLevel + 1,
            maxNestingLevel: maxNestingLevel,
            ancestorObjectIDs: ancestorObjectIDs
        )
    }

    func addingObjectID(_ objectID: ObjectIdentifier) -> Self {
        var ancestorObjectIDs = ancestorObjectIDs
        ancestorObjectIDs.insert(objectID)
        return .init(
            nestingLevel: nestingLevel,
            maxNestingLevel: maxNestingLevel,
            ancestorObjectIDs: ancestorObjectIDs
        )
    }
}

public func propertyCodeStrings<T>(
    _ value: T,
    maxValueWidth: Int = codeStringDefaultMaxWidth,
    maxNestingLevel: Int = codeStringDefaultMaxNestingLevel
) -> [CodePropertyValuePair] {
    let mirror = Mirror(reflecting: value)
    var res: [CodePropertyValuePair] = []
    switch mirror.displayStyle {
    case .class, .struct:
        for (propertyName, value) in mirror.children {
            guard let propertyName else {
                assertionFailure()
                continue
            }
            let strValue = (value as? String) ?? codeString(
                value,
                maxValueWidth: maxValueWidth,
                maxNestingLevel: maxNestingLevel
            )
            res.append(.init(property: propertyName, value: strValue))
        }
        return res
        
    default:
        return []
    }
}

public func singleLineCodeString<T>(
    _ value: T,
    indent: Int = 3,
    maxValueWidth: Int = codeStringDefaultMaxWidth,
    maxNestingLevel: Int = codeStringDefaultMaxNestingLevel
) -> String {
    codeStringImpl(
        value,
        delimiter: " ",
        offset: 0,
        indent: indent,
        maxValueWidth: maxValueWidth,
        context: .root(maxNestingLevel: maxNestingLevel)
    )
}

public func singleLineCodeString(
    name: String,
    properties: [String: Any],
    maxNestingLevel: Int = codeStringDefaultMaxNestingLevel
) -> String {
    var res = name
    res.append("(")
    var count = 0
    for (name, value) in properties.sorted(by: { $0.key < $1.key}) {
        res.append(name)
        res.append(": ")
        res.append(singleLineCodeString(value, maxNestingLevel: maxNestingLevel))
        count += 1
        if count < properties.count {
            res.append(", ")
        }
    }
    res.append(")")
    return res
}

public func codeString(
    name: String,
    properties: [String: Any],
    offset: Int = 0,
    indent: Int = 3,
    maxValueWidth: Int = codeStringDefaultMaxWidth,
    maxNestingLevel: Int = codeStringDefaultMaxNestingLevel
)
-> String {
    let singleLineValue = singleLineCodeString(
        name: name,
        properties: properties,
        maxNestingLevel: maxNestingLevel
    )
    if singleLineValue.count < maxValueWidth {
        return singleLineValue
    }
    
    var res = name
    if properties.isEmpty {
        res.append("())")
        return res
    }
    
    func indentString(offset: Int) -> String {
        String(repeating: " ", count: offset)
    }

    res.append("(\n")
    var count = 0
    for (name, value) in properties.sorted(by: { $0.key < $1.key}) {
        res.append(indentString(offset: offset + indent))
        res.append(name)
        res.append(": ")
        res.append(codeString(
            value,
            offset: offset + indent,
            indent: indent,
            maxValueWidth: maxValueWidth,
            maxNestingLevel: maxNestingLevel
        ))
        count += 1
        if count < properties.count {
            res.append(",\n")
        }
        else {
            res.append("\n")
        }
    }
    res.append(indentString(offset: offset))
    res.append(")")
    return res
}

public func codeString<T>(
    _ value: T,
    offset: Int = 0,
    indent: Int = 3,
    maxValueWidth: Int = codeStringDefaultMaxWidth,
    maxNestingLevel: Int = codeStringDefaultMaxNestingLevel
) -> String {
    codeStringImpl(
        value,
        delimiter: "\n",
        offset: offset,
        indent: indent,
        maxValueWidth: maxValueWidth,
        context: .root(maxNestingLevel: maxNestingLevel)
    )
}

private func codeStringImpl<T>(
    _ value: T,
    delimiter: Character,
    offset: Int,
    indent: Int,
    maxValueWidth: Int,
    context: CodeStringContext
) -> String {
    let forceSingleLine = (delimiter == " ")
    let mirror = Mirror(reflecting: value)
    var context = context

    if mirror.displayStyle != .optional {
        if let value = value as? CustomCodeStringConvertible {
            return value.codeStringDescription(offset: offset, indent: indent, maxValueWidth: maxValueWidth)
        }
        
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

        if isTerminalCodeStringValue(value) {
            return terminalCodeString(value, mirror: mirror)
        }
    }

    if mirror.displayStyle == .optional {
        if let (_, wrappedValue) = mirror.children.first {
            return codeStringImpl(
                wrappedValue,
                delimiter: delimiter,
                offset: offset,
                indent: indent,
                maxValueWidth: maxValueWidth,
                context: context
            )
        }
        else {
            return "nil"
        }
    }

    if !forceSingleLine {
        let singleLine = codeStringImpl(
            value,
            delimiter: " ",
            offset: offset,
            indent: indent,
            maxValueWidth: maxValueWidth,
            context: context
        )
        if (singleLine.count <= maxValueWidth) || forceSingleLine {
            return singleLine
        }
    }

    if let objectID = objectIdentifier(for: value, mirror: mirror) {
        guard !context.ancestorObjectIDs.contains(objectID) else {
            return circularReferenceCodeString(mirror)
        }
        context = context.addingObjectID(objectID)
    }

    if context.nestingLevel > context.maxNestingLevel {
        return truncatedCodeString(value, mirror: mirror)
    }
    
    func nestedCodeString<U>(_ value: U, offset: Int) -> String {
        codeStringImpl(
            value,
            delimiter: delimiter,
            offset: offset,
            indent: indent,
            maxValueWidth: maxValueWidth,
            context: context.descended()
        )
    }

    func nestedSingleLineCodeString<U>(_ value: U, offset: Int) -> String {
        codeStringImpl(
            value,
            delimiter: " ",
            offset: offset,
            indent: indent,
            maxValueWidth: maxValueWidth,
            context: context.descended()
        )
    }

    func indentString(offset: Int) -> String {
        guard !forceSingleLine else { return "" }
        return String(repeating: " ", count: offset)
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
            var caseValueStr = nestedSingleLineCodeString(caseValue, offset: offset + indent)
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
            valuesDict[nestedSingleLineCodeString(value, offset: offset + indent)] = value
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
                    key = nestedSingleLineCodeString(tupleValue, offset: offset + indent)
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
                nestedContent.append(nestedSingleLineCodeString(value, offset: nestedOffset))
                
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

private func objectIdentifier<T>(for value: T, mirror: Mirror) -> ObjectIdentifier? {
    guard mirror.displayStyle == .class, let object = value as AnyObject? else {
        return nil
    }
    return ObjectIdentifier(object)
}

private func circularReferenceCodeString(_ mirror: Mirror) -> String {
    "<circular: \(shortName("\(mirror.subjectType)"))>"
}

private func truncatedCodeString<T>(_ value: T, mirror: Mirror) -> String {
    switch mirror.displayStyle {
    case .tuple:
        return "(...)"

    case .collection:
        return "[...]"

    case .set:
        return "Set([...])"

    case .dictionary:
        return "[...]"

    case .enum:
        if let caseLabel = mirror.children.first?.label {
            return ".\(caseLabel)(...)"
        }
        else if value is CustomStringConvertible {
            return codeString(String(describing: value))
        }
        else {
            return ".\(value)"
        }

    default:
        let name = shortName("\(mirror.subjectType)")
        return "\(name)(...)"
    }
}

private func terminalCodeString<T>(_ value: T, mirror: Mirror) -> String {
    let description = String(describing: value)
    guard !description.isEmpty else {
        return shortName("\(mirror.subjectType)")
    }
    return description
}

private func isTerminalCodeStringValue<T>(_ value: T) -> Bool {
    #if canImport(Combine)
    if value is any Publisher {
        return true
    }
    #endif

    #if canImport(UIKit)
    if value is UIView || value is UIViewController {
        return true
    }
    #endif

    #if canImport(AppKit)
    if value is NSView || value is NSViewController {
        return true
    }
    #endif

    #if canImport(QuartzCore)
    if value is CALayer {
        return true
    }
    #endif

    return false
}
