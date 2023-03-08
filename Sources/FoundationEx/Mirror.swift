//
//  Mirror.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation

public func propertyCodeStrings<T>(_ value: T,  maxValueWidth: Int = 50) -> [String: String] {
    let mirror = Mirror(reflecting: value)
    var res: [String: String] = [:]
    switch mirror.displayStyle {
    case .class, .struct:
        for (propertyName, value) in mirror.children {
            guard let propertyName else {
                assertionFailure()
                continue
            }
            res[propertyName] = codeString(value, maxValueWidth: maxValueWidth)
        }
        return res
        
    default:
        return [:]
    }
}

public func isSimpleLiteral<T>(_ value: T) -> Bool {
    if value is any ExpressibleByNilLiteral {
        return false
    }
    
    if value is any ExpressibleByBooleanLiteral {
        return true
    }
    
    if value is any ExpressibleByIntegerLiteral {
        return true
    }
    
    if value is any ExpressibleByFloatLiteral {
        return true
    }
    
    if value is any ExpressibleByStringLiteral {
        return true
    }
    
    return false
}

public func codeString<T>(_ value: T, offset: Int = 0, indent: Int = 3, maxValueWidth: Int = 50) -> String {
    if let strValue = value as? String {
        return "\"\(strValue)\""
    }

    if isSimpleLiteral(value) {
        return String(describing: value)
    }

    func nestedCodeString<U>(_ value: U, offset: Int) -> String {
        codeString(value, offset: offset, indent: indent, maxValueWidth: maxValueWidth)
    }
    
    func indentString(offset: Int) -> String {
        String(repeating: " ", count: offset)
    }
    
    let singleLine = singleLineCodeString(value)
    if singleLine.count <= maxValueWidth {
        return singleLine
    }
    
    let mirror = Mirror(reflecting: value)
    var res = ""
    
    func addNestedContent(_ nestedContent: String) -> Bool {
        guard nestedContent.count <= maxValueWidth else { return false }
        res.append(indentString(offset: offset + indent))
        res.append(nestedContent)
        res.append("\n")
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
            if res.count > maxValueWidth {
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
        else {
            res = ".\(value)"
        }

   case .tuple:
        res.append("(\n")
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for (label, value) in mirror.children {
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
        
    case .optional:
        if let (_, value) = mirror.children.first {
            res.append(nestedCodeString(value, offset: offset))
        }
        else {
            res.append("nil")
        }
        
    case .collection:
        res.append("[\n")
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for (label, value) in mirror.children {
            if !isFirst {
                res.append(",\n")
            }
            else {
                isFirst = false
            }
            
            assert(label == nil)
            res.append(nestedOffsetStr)
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        res.append("\n")
        res.append(indentString(offset: offset))
        res.append("]")

    case .set:
        var valuesDict: [String: Any] = [:]
        for (label, value) in mirror.children {
            assert(label == nil)
            valuesDict[singleLineCodeString(value)] = value
        }
        
        res.append("Set([\n")
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for key in valuesDict.keys.sorted() {
            guard let value = valuesDict[key] else {
                assertionFailure()
                continue
            }
            
            if !isFirst {
                res.append(",\n")
            }
            else {
                isFirst = false
            }

            res.append(nestedOffsetStr)
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        res.append("\n")
        res.append(indentString(offset: offset))
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

        res.append("[\n")
        let nestedOffset = offset + indent
        let nestedOffsetStr = indentString(offset: nestedOffset)
        var isFirst = true
        for key in dict.keys.sorted() {
            guard let value = dict[key] else {
                assertionFailure()
                continue
            }

            if !isFirst {
                res.append(",\n")
            }
            else {
                isFirst = false
            }
            res.append(nestedOffsetStr)
            res.append("\(key): ")
            res.append(nestedCodeString(value, offset: nestedOffset))
        }
        res.append("\n")
        res.append(indentString(offset: offset))
        res.append("]")

    default: // struct, class, and unknown
        let name = "\(mirror.subjectType)"
        let shortName = shortName(name)
        res.append(shortName)
        res.append("(\n")
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

private func singleLineCodeString<T>(_ value: T) -> String {
    if let strValue = value as? String {
        return "\"\(strValue)\""
    }

    if isSimpleLiteral(value) {
        return String(describing: value)
    }

    let mirror = Mirror.init(reflecting: value)
    var res = ""
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
            res.append(".\(caseLabel)(\(caseValueStr))")
        }
        else {
            res = ".\(value)"
        }

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
            res.append(singleLineCodeString(value))
        }
        res.append(")")
        
    case .optional:
        if let (_, value) = mirror.children.first {
            res.append(singleLineCodeString(value))
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
            res.append(singleLineCodeString(value))
        }
        res.append("]")
        
    case .set:
        var values: [String] = []
        for (label, value) in mirror.children {
            assert(label == nil)
            values.append(singleLineCodeString(value))
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
                    key = singleLineCodeString(tupleValue)
                }
                else if index == 1 {
                    value = singleLineCodeString(tupleValue)
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

    default: // struct, class, and unknown
        let name = "\(mirror.subjectType)"
        let shortName = shortName(name)
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
            res.append(singleLineCodeString(value))
        }
        res.append(")")
    }
    return res
}

private func shortName(_ name: String) -> String {
    name.split(separator: ".").last.map { String($0) } ?? name
}
