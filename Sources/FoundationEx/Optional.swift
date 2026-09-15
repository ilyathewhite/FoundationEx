//
//  Optional.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/19/21.
//

import Foundation

extension Optional: @retroactive Identifiable where Wrapped: Identifiable {
    public var id: Wrapped.ID? {
        self?.id
    }
}
