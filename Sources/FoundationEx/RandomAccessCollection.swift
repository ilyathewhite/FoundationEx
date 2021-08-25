//
//  RandomAccessCollection.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/25/21.
//

extension RandomAccessCollection {
    public func stableSorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> [Element] {
        let sorted = try enumerated().sorted { lhs, rhs in
            if try areInIncreasingOrder(lhs.element, rhs.element) {
                return true
            }
            else if try areInIncreasingOrder(rhs.element, lhs.element) {
                return false
            }
            else {
                return lhs.offset < rhs.offset
            }
        }
        return sorted.map(\.element)
    }
}
