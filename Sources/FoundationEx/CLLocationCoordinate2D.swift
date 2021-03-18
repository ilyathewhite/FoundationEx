//
//  CLLocationCoordinate2D.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 10/20/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation
import MapKit

public extension CLLocationCoordinate2D {
    func region(radius miles: Double) -> MKCoordinateRegion {
        let scalingFactor = abs(cos((2 * Double.pi) * latitude / 360.0))
        return MKCoordinateRegion(center: self, span: MKCoordinateSpan(latitudeDelta: miles / 69.0, longitudeDelta: miles / (scalingFactor * 69.0)))
    }
}
