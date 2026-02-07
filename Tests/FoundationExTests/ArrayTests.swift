//
//  ArrayTests.swift
//
//  Created by Ilya Belenkiy on 11/13/23.
//

import Foundation
import XCTest
import FoundationEx

class ArrayTests: XCTestCase {
    func testMedian1() {
        let array: [Double] = []
        let median = array.median()
        XCTAssertEqual(median, nil)
    }

    func testMedian2() {
        let array: [Double] = [7]
        let median = array.median()
        XCTAssertEqual(median, 7)
    }

    func testMedian3() {
        let array: [Double] = [7, 3]
        let median = array.median()
        XCTAssertEqual(median, 5)
    }

    func testMedian4() {
        let array: [Double] = [1, 2, 5, 25]
        let median = array.median()
        XCTAssertEqual(median, 3.5)
    }

    func testMedian5() {
        let array: [Double] = [1, 2, 5, 25, 49]
        let median = array.median()
        XCTAssertEqual(median, 5)
    }

    func testConcurrentMapPreservesOrder() async {
        let values = [1, 2, 3, 4, 5]

        let result = await values.concurrentMap { value in
            let delay = UInt64((6 - value) * 1_000_000)
            try? await Task.sleep(nanoseconds: delay)
            return value * value
        }

        XCTAssertEqual(result, [1, 4, 9, 16, 25])
    }

    func testConcurrentMapWithEmptyArray() async {
        let result = await [Int]().concurrentMap { value in
            value * value
        }
        XCTAssertEqual(result, [])
    }
}
