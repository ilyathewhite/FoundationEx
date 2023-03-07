//
//  MirrorTest.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation
import XCTest
import FoundationEx

class CodeStringTests: XCTestCase {
    func testSimpleEnum() {
        enum Simple {
            case one
            case two
        }
        
        let value1: Simple = .one
        XCTAssertEqual(codeString(value1), ".one")
        
        let value2: Simple = .two
        XCTAssertEqual(codeString(value2), ".two")
    }
    
    func testEnumWithValues() {
        enum Simple2 {
            case one
            case two(String)
            case three(text: String)
            case four(number: Int)
        }
        
        let value1: Simple2 = .one
        XCTAssertEqual(codeString(value1), ".one")
        
        let value2: Simple2 = .two("text")
        XCTAssertEqual(codeString(value2), ".two(\"text\")")
        
        let value3: Simple2 = .three(text: "hello")
        XCTAssertEqual(codeString(value3), ".three(text: \"hello\")")
        
        let value4: Simple2 = .four(number: 57)
        XCTAssertEqual(codeString(value4), ".four(number: 57)")
    }
    
    func testStruct() {
        struct Simple3 {
            let intValue: Int
            let doubleValue: Double
            let stringValue: String
        }
        
        let value: Simple3 = .init(intValue: 1, doubleValue: 1.23, stringValue: "one")
        XCTAssertEqual(codeString(value), "Simple3(intValue: 1, doubleValue: 1.23, stringValue: \"one\")")
    }
    
    func testClass() {
        class Simple4 {
            let intValue: Int
            let doubleValue: Double
            let stringValue: String
            
            init(intValue: Int, doubleValue: Double, stringValue: String) {
                self.intValue = intValue
                self.doubleValue = doubleValue
                self.stringValue = stringValue
            }
        }
        
        let value: Simple4 = .init(intValue: 1, doubleValue: 1.23, stringValue: "one")
        XCTAssertEqual(codeString(value), "Simple4(intValue: 1, doubleValue: 1.23, stringValue: \"one\")")
    }
    
    func testTuple() {
        let tuple1 = (1, "one")
        XCTAssertEqual(codeString(tuple1), "(1, \"one\")")
        
        let tuple2 = (number: 1, string: "one",  2)
        XCTAssertEqual(codeString(tuple2), "(number: 1, string: \"one\", 2)")

        let tuple3 = ((1, 2), test: (3, 4, 5))
        XCTAssertEqual(codeString(tuple3), "((1, 2), test: (3, 4, 5))")
    }
    
    func testOptional() {
        let maybeInt: Int? = nil
        XCTAssertEqual(codeString(maybeInt), "nil")
        
        let maybeInt2: Int? = 1
        XCTAssertEqual(codeString(maybeInt2), "1")
    }
    
    func testCollection() {
        let ints = [1, 2, 3]
        XCTAssertEqual(codeString(ints), "[1, 2, 3]")
        
        let tuples = [(1, 2), (3, 4), (5, 6)]
        XCTAssertEqual(codeString(tuples), "[(1, 2), (3, 4), (5, 6)]")
    }
    
    func testSet() {
        let intsSet = Set([1, 2])
        let codeStringVal = codeString(intsSet)
        if codeStringVal == "Set([2, 1])" {
            return
        }
        else if codeStringVal == "Set([1, 2])" {
            return
        }
        else {
            XCTFail()
        }
    }
    
    func testDictionary() {
        let intToString: [Int: String] = [1: "a", 2: "b"]
        let codeStringVal = codeString(intToString)
        if codeStringVal == "[1: \"a\", 2: \"b\"]" {
            return
        }
        else if codeStringVal == "[2: \"b\", 1: \"a\"]" {
            return
        }
        else {
            XCTFail()
        }
    }
    
    func testCombined() {
        struct Compound {
            enum Simple5 {
                case one
                case two(String, int: Int)
            }
            
            enum Simple6 {
                case three(Simple5)
            }
            
            var a: Simple5
            var b: Simple6
        }
        
        let value: Compound = .init(a: .one, b: .three(.two("a", int: 1)))
        XCTAssertEqual(codeString(value), "Compound(a: .one, b: .three(.two(\"a\", int: 1)))")
    }
}
