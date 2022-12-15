//
//  AnySequence.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 12/14/22.
//

public extension AnySequence {
    func transform<T>(_ transform: @escaping (Element) throws -> T) rethrows -> AnySequence<T> {
        let iterator = makeIterator()
        return AnySequence<T> {
            AnyIterator<T> {
                guard let value = iterator.next() else { return nil }
                return try? transform(value)
            }
        }
    }
}
