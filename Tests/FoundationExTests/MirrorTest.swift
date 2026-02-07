//
//  MirrorTest.swift
//
//  Created by Ilya Belenkiy on 3/6/23.
//

import Foundation
import Testing
import FoundationEx

@Suite
struct CodeStringTests {
    @Test
    func literals() {
        #expect(codeString(123) == "123")
        #expect(codeString("123") == "\"123\"")
        
        let intNil: Int? = nil
        #expect(codeString(intNil) == "nil")

        let strNil: String? = nil
        #expect(codeString(strNil) == "nil")
        
        let strWithZero = "ab\0c"
        #expect(codeString(strWithZero) == "\"ab\\0c\"")
        
        let strWithSlash = "ab\\c"
        #expect(codeString(strWithSlash) == "\"ab\\\\c\"")
        
        let strWithTab = "ab\tc"
        #expect(codeString(strWithTab) == "\"ab\\tc\"")

        let strWithNewLine = "ab\nc"
        #expect(codeString(strWithNewLine) == "\"ab\\nc\"")
        
        let strWithCarriageReturn = "ab\rc"
        #expect(codeString(strWithCarriageReturn) == "\"ab\\rc\"")

        let strWithQuote = "ab\"c"
        #expect(codeString(strWithQuote) == "\"ab\\\"c\"")

        let strWithSingleQuote = "ab\'c"
        #expect(codeString(strWithSingleQuote) == "\"ab\\\'c\"")
    }
    
    
    @Test
    func literals2() {
        enum Finger: Int, CustomStringConvertible {
            case index = 0
            case middle = 1
            case ring = 2
            case none = -1

            public var description: String { symbol }

            public var symbol: String {
                switch self {
                case .index: return "1"
                case .middle: return "2"
                case .ring: return "3"
                case .none: return " "
                }
            }
        }
        
        let finger1: Finger = .none
        #expect(codeString(finger1) == "\" \"")

        let finger2: Finger = .index
        #expect(codeString(finger2) == "\"1\"")
    }
    
    @Test
    func simpleEnum() {
        enum Simple {
            case one
            case two
        }
        
        let value1: Simple = .one
        #expect(codeString(value1) == ".one")
        
        let value2: Simple = .two
        #expect(codeString(value2) == ".two")
    }
    
    @Test
    func enumWithValues() {
        enum Simple2 {
            case one
            case two(String)
            case three(text: String)
            case four(number: Int)
        }
        
        let value1: Simple2 = .one
        #expect(codeString(value1) == ".one")
        #expect(caseName(value1) == "one")
        
        let value2: Simple2 = .two("text")
        #expect(codeString(value2) == ".two(\"text\")")
        #expect(caseName(value2) == "two")

        let value3: Simple2 = .three(text: "hello")
        #expect(codeString(value3) == ".three(text: \"hello\")")
        #expect(caseName(value3) == "three")

        let value4: Simple2 = .four(number: 57)
        #expect(codeString(value4) == ".four(number: 57)")
        #expect(caseName(value4) == "four")
    }
    
    @Test
    func structValues() {
        struct Simple3 {
            let intValue: Int
            let doubleValue: Double
            let stringValue: String
        }
        
        let value: Simple3 = .init(intValue: 1, doubleValue: 1.23, stringValue: "one")
        #expect(codeString(value, maxValueWidth: 100) == "Simple3(intValue: 1, doubleValue: 1.23, stringValue: \"one\")")
                
        struct OnePropertyStruct {
            let intValue: Int
        }
        
        let value2 = OnePropertyStruct(intValue: 1)
        #expect(codeString(value2) == "OnePropertyStruct(intValue: 1)")
        
        struct EmptyStruct {
        }
        
        let value3 = EmptyStruct()
        #expect(codeString(value3) == "EmptyStruct()")
    }
    
    @Test
    func classValues() {
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
        #expect(codeString(value, maxValueWidth: 100) == "Simple4(intValue: 1, doubleValue: 1.23, stringValue: \"one\")")
        
        struct OnePropertyClass {
            let intValue: Int
            
            init(intValue: Int) {
                self.intValue = intValue
            }
        }
        
        let value2 = OnePropertyClass(intValue: 1)
        #expect(codeString(value2) == "OnePropertyClass(intValue: 1)")
        
        struct EmptyClass {
        }
        
        let value3 = EmptyClass()
        #expect(codeString(value3) == "EmptyClass()")
    }
    
    @Test
    func tuple() {
        let voidTuple: (Void) = ()
        #expect(codeString(voidTuple) == "()")

        let tuple1 = (1, "one")
        #expect(codeString(tuple1) == "(1, \"one\")")
        
        let tuple2 = (number: 1, string: "one",  2)
        #expect(codeString(tuple2) == "(number: 1, string: \"one\", 2)")

        let tuple3 = ((1, 2), test: (3, 4, 5))
        #expect(codeString(tuple3) == "((1, 2), test: (3, 4, 5))")
    }
    
    @Test
    func optional() {
        let maybeInt: Int? = nil
        #expect(codeString(maybeInt) == "nil")
        
        let maybeInt2: Int? = 1
        #expect(codeString(maybeInt2) == "1")
    }
    
    @Test
    func collection() {
        let ints = [1, 2, 3]
        #expect(codeString(ints) == "[1, 2, 3]")
        
        let testOneInt: [Int] = [1]
        #expect(codeString(testOneInt) == "[1]")

        let testNoInts: [Int] = []
        #expect(codeString(testNoInts) == "[]")
        
        let tuples = [(1, 2), (3, 4), (5, 6)]
        #expect(codeString(tuples) == "[(1, 2), (3, 4), (5, 6)]")
    }
    
    @Test
    func set() {
        let intsSet = Set([3, 1, 2, 5, 4])
        #expect(codeString(intsSet) == "Set([1, 2, 3, 4, 5])")
        
        let oneElemSet = Set([1])
        #expect(codeString(oneElemSet) == "Set([1])")

        let emptySet: Set<Int> = Set([])
        #expect(codeString(emptySet) == "Set([])")
    }
    
    @Test
    func dictionary() {
        let intToString: [Int: String] = [1: "a", 3: "c", 2: "b"]
        #expect(codeString(intToString) == "[1: \"a\", 2: \"b\", 3: \"c\"]")
        
        let oneElemDict: [Int: String] = [1: "a"]
        #expect(codeString(oneElemDict) == "[1: \"a\"]")
        
        let emptyDict: [Int: String] = [:]
        #expect(codeString(emptyDict) == "[:]")
    }
    
    @Test
    func combined() {
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
        #expect(codeString(value) == "Compound(a: .one, b: .three(.two(\"a\", int: 1)))")
    }
    
    @Test
    func largeNestedTupleInEnum() {
        enum Nested {
            case content(a: String, b: String, c: String)
        }
        
        enum Container {
            case content(String, two: String, three: Nested, four: String, five: String)
        }
        
        let value: Container = .content("one", two: "two", three: .content(a: "one", b: "two", c: "three"), four: "four", five: "five")
        
        let strWidth20 = """
        .content(
           "one",
           two: "two",
           three: .content(
              a: "one",
              b: "two",
              c: "three"
           ),
           four: "four",
           five: "five"
        )
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)
        
        let strWidth30 = """
        .content(
           "one",
           two: "two",
           three: .content(
              a: "one", b: "two", c: "three"
           ),
           four: "four",
           five: "five"
        )
        """
        #expect(codeString(value, maxValueWidth: 30) == strWidth30)
        
        let strWidth40 = """
        .content(
           "one",
           two: "two",
           three: .content(a: "one", b: "two", c: "three"),
           four: "four",
           five: "five"
        )
        """
        #expect(codeString(value, maxValueWidth: 40) == strWidth40)
    }
    
    @Test
    func largeStruct() {
        struct Large {
            let one: String
            let two: String
            let three: String
        }
        
        let value: Large = .init(one: "one", two: "two", three: "three")
        
        let strWidth20 = """
        Large(
           one: "one",
           two: "two",
           three: "three"
        )
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)
        
        let strWidth50 = """
        Large(one: "one", two: "two", three: "three")
        """
        #expect(codeString(value, maxValueWidth: 50) == strWidth50)
    }
    
    @Test
    func largeTuple() {
        let value = (one: "one", two: "two", three: "three")
        
        let strWidth20 = """
        (
           one: "one",
           two: "two",
           three: "three"
        )
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)

        let strWidth50 = """
        (one: "one", two: "two", three: "three")
        """
        #expect(codeString(value, maxValueWidth: 50) == strWidth50)
    }
    
    @Test
    func largeCollection() {
        let value = ["one", "two", "three", "four", "five"]
        
        let strWidth20 = """
        [
           "one",
           "two",
           "three",
           "four",
           "five"
        ]
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)
        
        let strWidth50 = """
        ["one", "two", "three", "four", "five"]
        """
        #expect(codeString(value, maxValueWidth: 50) == strWidth50)
    }
    
    @Test
    func largeSet() {
        let value = Set(["1 - one", "2 - two", "3 - three", "4 - four", "5 - five"])
        
        let strWidth20 = """
        Set([
           "1 - one",
           "2 - two",
           "3 - three",
           "4 - four",
           "5 - five"
        ])
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)
        
        let strWidth100 = """
        Set(["1 - one", "2 - two", "3 - three", "4 - four", "5 - five"])
        """
        #expect(codeString(value, maxValueWidth: 100) == strWidth100)
    }
    
    @Test
    func largeDictionary() {
        let value = ["1 - one": 1, "2 - two": 2, "3 - three": 3, "4 - four": 4, "5 - five": 5]
        
        let strWidth20 = """
        [
           "1 - one": 1,
           "2 - two": 2,
           "3 - three": 3,
           "4 - four": 4,
           "5 - five": 5
        ]
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)
        
        let strWidth100 = """
        ["1 - one": 1, "2 - two": 2, "3 - three": 3, "4 - four": 4, "5 - five": 5]
        """
        #expect(codeString(value, maxValueWidth: 100) == strWidth100)
    }
    
    @Test
    func largeStruct2() {
        struct Large2 {
            enum Either<T> {
                case left(T)
                case right(T)
            }
            
            enum TupleContainer {
                case tuple(number: Int, string: String)
            }
            
            struct Simple {
                let one: String
                let two: String
                let three: String
            }
            
            let string: String
            let tuple: (one: String, Double, two: [Int])
            let eitherDict: Either<[Int: String]>
            let eitherSimple: Either<Simple>
            let tupleContainer: TupleContainer
        }
        
        let value: Large2 = .init(
            string: "abc",
            tuple: (
                one: "Hello", 3.14159, two: [23, 75, 89]
            ),
            eitherDict: .left([1: "one", 2: "two", 3: "three"]),
            eitherSimple: .right(.init(one: "one", two: "two", three: "three")),
            tupleContainer: .tuple(number: 2, string: "two")
        )
        
        let strWidth20 = """
        Large2(
           string: "abc",
           tuple: (
              one: "Hello",
              3.14159,
              two: [23, 75, 89]
           ),
           eitherDict: .left([
              1: "one",
              2: "two",
              3: "three"
           ]),
           eitherSimple: .right(
              Simple(
                 one: "one",
                 two: "two",
                 three: "three"
              )
           ),
           tupleContainer: .tuple(
              number: 2,
              string: "two"
           )
        )
        """
        #expect(codeString(value, maxValueWidth: 20) == strWidth20)
        
        let strWidth30 = """
        Large2(
           string: "abc",
           tuple: (
              one: "Hello",
              3.14159,
              two: [23, 75, 89]
           ),
           eitherDict: .left([
              1: "one",
              2: "two",
              3: "three"
           ]),
           eitherSimple: .right(
              Simple(
                 one: "one",
                 two: "two",
                 three: "three"
              )
           ),
           tupleContainer: .tuple(
              number: 2, string: "two"
           )
        )
        """
        #expect(codeString(value, maxValueWidth: 30) == strWidth30)

        let strWidth40 = """
        Large2(
           string: "abc",
           tuple: (
              one: "Hello",
              3.14159,
              two: [23, 75, 89]
           ),
           eitherDict: .left([1: "one", 2: "two", 3: "three"]),
           eitherSimple: .right(
              Simple(
                 one: "one", two: "two", three: "three"
              )
           ),
           tupleContainer: .tuple(number: 2, string: "two")
        )
        """
        #expect(codeString(value, maxValueWidth: 40) == strWidth40)

        let strWidth50 = """
        Large2(
           string: "abc",
           tuple: (one: "Hello", 3.14159, two: [23, 75, 89]),
           eitherDict: .left([1: "one", 2: "two", 3: "three"]),
           eitherSimple: .right(
              Simple(one: "one", two: "two", three: "three")
           ),
           tupleContainer: .tuple(number: 2, string: "two")
        )
        """
        #expect(codeString(value, maxValueWidth: 50) == strWidth50)

        let strWidth60 = """
        Large2(
           string: "abc",
           tuple: (one: "Hello", 3.14159, two: [23, 75, 89]),
           eitherDict: .left([1: "one", 2: "two", 3: "three"]),
           eitherSimple: .right(Simple(one: "one", two: "two", three: "three")),
           tupleContainer: .tuple(number: 2, string: "two")
        )
        """
        #expect(codeString(value, maxValueWidth: 60) == strWidth60)
    }
    
    @Test
    func propertyCodeStringsValues() {
        struct Simple {
            let intValue: Int
            let doubleValue: Double
            let stringValue: String
        }
        
        let value: Simple = .init(intValue: 1, doubleValue: 3.14, stringValue: "abc")
        let content = propertyCodeStrings(value)
        let expected: [CodePropertyValuePair] = [
            .init(property: "intValue", value: "1"),
            .init(property: "doubleValue", value: "3.14"),
            .init(property: "stringValue", value: "abc")
         ]
        #expect(content == expected)
    }
    
    @Test
    func codeStringFromProperties() {
        struct Simple {
            let intValue: Int
            let doubleValue: Double
            let stringValue: String
        }

        let value = codeString(
            name: "MyStruct",
            properties: ["a": 1, "b": 2, "c": Simple(intValue: 1, doubleValue: 2.5, stringValue: "abc")]
        )
        
        let expected = """
        MyStruct(
           a: 1,
           b: 2,
           c: Simple(
              intValue: 1, doubleValue: 2.5, stringValue: "abc"
           )
        )
        """
        #expect(value == expected)
    }
    
    @Test
    func codeStringFromProperties2() {
        struct Simple {
            let x: Int
            let y: Double
            let z: String
        }

        let value = codeString(
            name: "MyStruct",
            properties: ["a": 1, "b": 2, "c": Simple(x: 1, y: 2.5, z: "abc")],
            maxValueWidth: .max
        )
        
        let expected = """
        MyStruct(a: 1, b: 2, c: Simple(x: 1, y: 2.5, z: "abc"))
        """
        #expect(value == expected)
    }

    @Test
    func codeStringFromProperties3() {
        struct Simple {
            let intValue: Int
            let doubleValue: Double
            let stringValue: String
        }
        
        struct Pair {
            let left: Simple
            let right: Simple
        }

        let value = codeString(
            name: "MyStruct",
            properties: [
                "a": 1, 
                "b": Pair(
                    left: Simple(
                        intValue: 1, doubleValue: 2.7, stringValue: "3.14"
                    ),
                    right: Simple(
                        intValue: 5, doubleValue: 121.9, stringValue: "hello"
                    )
                ),
                "c": 3
            ]
        )
        
        let expected = """
        MyStruct(
           a: 1,
           b: Pair(
              left: Simple(
                 intValue: 1, doubleValue: 2.7, stringValue: "3.14"
              ),
              right: Simple(
                 intValue: 5,
                 doubleValue: 121.9,
                 stringValue: "hello"
              )
           ),
           c: 3
        )
        """
        #expect(value == expected)
    }

}
