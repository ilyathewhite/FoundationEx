//
//  Result.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 6/11/20.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

import Foundation

extension Result: Decodable where Success: Decodable, Failure: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            let decodedValue = try Success(from: decoder)
            self = .success(decodedValue)
        }
        catch {
            let outerError = error
            do {
                let decodedError = try Failure(from: decoder)
                self = .failure(decodedError)
            }
            catch {
                FoundationEx.env.logCodingError(outerError)
                throw error
            }
        }
    }
}

extension Result: CodingKeyValue where Success: CodingKeyValue, Failure: Decodable {
}
