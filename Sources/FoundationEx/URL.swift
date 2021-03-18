//
//  URL.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 6/9/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

public extension URL {
    init(staticString string: StaticString) {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid static URL string: \(string)")
        }

        self = url
    }
}
