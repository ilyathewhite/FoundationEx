//
//  ArrayTests.swift
//
//  Created by Ilya Belenkiy on 11/13/23.
//

import Foundation
import Testing
import FoundationEx

@Suite
struct ArrayTests {
    @Test
    func median1() {
        let array: [Double] = []
        let median = array.median()
        #expect(median == nil)
    }

    @Test
    func median2() {
        let array: [Double] = [7]
        let median = array.median()
        #expect(median == 7)
    }

    @Test
    func median3() {
        let array: [Double] = [7, 3]
        let median = array.median()
        #expect(median == 5)
    }

    @Test
    func median4() {
        let array: [Double] = [1, 2, 5, 25]
        let median = array.median()
        #expect(median == 3.5)
    }

    @Test
    func median5() {
        let array: [Double] = [1, 2, 5, 25, 49]
        let median = array.median()
        #expect(median == 5)
    }

    @Test
    func concurrentMapPreservesOrder() async {
        let values = [1, 2, 3, 4, 5]

        let result = await values.concurrentMap { value in
            let delay = UInt64((6 - value) * 1_000_000)
            try? await Task.sleep(nanoseconds: delay)
            return value * value
        }

        #expect(result == [1, 4, 9, 16, 25])
    }

    @Test
    func concurrentMapWithEmptyArray() async {
        let result = await [Int]().concurrentMap { value in
            value * value
        }
        #expect(result == [])
    }
}
