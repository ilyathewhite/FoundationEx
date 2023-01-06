//
//  AnySequence.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 12/14/22.
//

public extension AnySequence {
    func mapAsSequence<T>(_ transform: @escaping (Element) throws -> T) rethrows -> AnySequence<T> {
        let iterator = makeIterator()
        return AnySequence<T> {
            AnyIterator<T> {
                guard let value = iterator.next() else { return nil }
                return try? transform(value)
            }
        }
    }

    func filterAsSequence(_ isIncluded: @escaping (Element) -> Bool) -> AnySequence<Element> {
        let iterator = makeIterator()
        return AnySequence<Element> {
            AnyIterator<Element> {
                while let value = iterator.next() {
                    if isIncluded(value) {
                        return value
                    }
                }
                return nil
            }
        }
    }
}
