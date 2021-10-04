//
//  Collection.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 10/2/21.
//

import Foundation

public extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Collection {
    func identifiableValues() -> [IdentifiableValue<Element>] {
        map { .init($0) }
    }
}
