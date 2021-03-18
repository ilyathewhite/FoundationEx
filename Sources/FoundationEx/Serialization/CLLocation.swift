//
//  CLLocation.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 2/14/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocation: PropertyListRepresentable {
    private static let latitudeKey = "latitude"
    private static let longitudeKey = "longitude"

    public func encode() -> PropertyListDict {
        var dict: PropertyListDict = [:]
        dict.set(coordinate.latitude, forKey: Self.latitudeKey)
        dict.set(coordinate.longitude, forKey: Self.longitudeKey)
        return dict
    }

    public static func decode(_ dict: PropertyListDict) throws  -> Self {
        do {
            return try .init(
                latitude: dict.get(Self.latitudeKey),
                longitude: dict.get(Self.longitudeKey)
            )
        }
        catch {
            throw PropertyListError<Self>.decode(error)
        }
    }
}
