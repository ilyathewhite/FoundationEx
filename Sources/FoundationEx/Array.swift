//
//  Array.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 10/15/21.
//

import Foundation

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
