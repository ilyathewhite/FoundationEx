//
//  Comparable.swift
//
//  Created by Ilya Belenkiy on 7/29/23.
//

public extension Comparable {
    func clamped(_ x: Self, _ y: Self) -> Self {
        min(max(self, x), y)
    }
}
