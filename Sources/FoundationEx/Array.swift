//
//  Array.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 10/15/21.
//

import Foundation

public extension Array {
    func concurrentMap<T>(_ transform: @escaping (Element) async -> T) async -> [T] {
        await withTaskGroup(of: (Int, T).self) { group in
            for (index, element) in enumerated() {
                group.addTask {
                    (index, await transform(element))
                }
            }

            var valuesByIndex = [Int: T]()
            for await (index, value) in group {
                valuesByIndex[index] = value
            }

            return (0..<count).compactMap { valuesByIndex[$0] }
        }
    }
}

public extension Array where Element: Hashable {
    func uniqueElements() -> Self {
        var elementSet = Set<Element>()
        var res = Self()
        for element in self {
            if elementSet.contains(element) {
                continue
            }
            elementSet.insert(element)
            res.append(element)
        }
        return res
    }
}

public extension Array where Element == Double {
    func median() -> Element? {
        guard !isEmpty else { return nil }
        let sortedArray = self.sorted()
        if sortedArray.count % 2 == 1 {
            let index = sortedArray.count / 2
            return sortedArray[index]
        }
        else {
            let index2 = sortedArray.count / 2
            let index1 = index2 - 1
            return (sortedArray[index1] + sortedArray[index2]) / 2.0
        }
    }
}
