//
//  AnyAsyncSequence.swift
//  FoundationEx
//
//  Created by Ilya Belenkiy on 6/19/25.
//

public struct AnyAsyncSequence<Element>: AsyncSequence {
    let _makeAsyncIterator: () -> AnyAsyncIterator

    public struct AnyAsyncIterator: AsyncIteratorProtocol {
        private let _next: () async throws -> Element?

        init<S: AsyncSequence>(_ seq: S) where S.Element == Element {
            var iterator = seq.makeAsyncIterator()
            self._next = { try await iterator.next() }
        }

        public mutating func next() async throws -> Element? {
            try await _next()
        }
    }

    init<S: AsyncSequence>(seq: S) where S.Element == Element {
        _makeAsyncIterator = { AnyAsyncIterator(seq) }
    }

    public func makeAsyncIterator() -> AnyAsyncIterator {
        _makeAsyncIterator()
    }
}

public extension AsyncSequence {
    func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
        AnyAsyncSequence(seq: self)
    }
}
