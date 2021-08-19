//
//  Identifiable.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 8/19/21.
//

import Foundation

public protocol IdentifiableAsSelf: Identifiable {
}

public extension IdentifiableAsSelf {
    var id: Self {
        self
    }
}
