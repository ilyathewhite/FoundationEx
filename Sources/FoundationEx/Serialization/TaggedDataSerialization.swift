//
//  AppDataSerialization.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 2/19/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation
import CoreLocation
import Tagged

extension Tagged: RawValueRepresentable {}
extension Tagged: PropertyListRepresentable where RawValue: PropertyListRepresentable {
    public typealias PropertyListValue = RawValue
}
extension Tagged: PropertyListRepresentableAsRawValue where RawValue: PropertyListRepresentable {}
