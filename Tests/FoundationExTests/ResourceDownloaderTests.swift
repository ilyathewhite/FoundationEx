//
//  ResourceDownloaderTests.swift
//
//  Created by Codex on 4/11/26.
//

import Foundation
import Testing
import FoundationEx

@Suite(.serialized)
struct ResourceDownloaderTests {
    @Test
    func returnsCachedProcessedValueWithoutRepeatingRequest() async throws {
        let url = URL(string: "https://foundationex.test/cached")!
        try await withRegisteredMockURLProtocol(responses: [
            url: .init(data: Data("hello".utf8))
        ]) {
            let downloader = ResourceDownloader<String>(maxConcurrentCount: 1)

            let first = try await downloader.download(url: url) { data in
                String(decoding: data, as: UTF8.self).uppercased()
            }
            let second = try await downloader.download(url: url) { _ in
                "should not run"
            }

            #expect(first == "HELLO")
            #expect(second == "HELLO")
            #expect(MockURLProtocol.requestCount(for: url) == 1)
        }
    }

    @Test
    func respectsMaximumConcurrentDownloads() async throws {
        let urls = (1...3).map { URL(string: "https://foundationex.test/item-\($0)")! }
        let responses = Dictionary(
            uniqueKeysWithValues: urls.enumerated().map { index, url in
                (url, MockURLProtocol.MockResponse(data: Data("\(index + 1)".utf8), delay: 20_000_000))
            }
        )

        try await withRegisteredMockURLProtocol(responses: responses) {
            let downloader = ResourceDownloader<Int>(maxConcurrentCount: 1)
            let values = try await withThrowingTaskGroup(of: Int.self) { group in
                for url in urls {
                    group.addTask {
                        try await downloader.download(url: url) { data in
                            Int(String(decoding: data, as: UTF8.self))!
                        }
                    }
                }

                var values: [Int] = []
                for try await value in group {
                    values.append(value)
                }
                return values.sorted()
            }

            #expect(values == [1, 2, 3])
            #expect(MockURLProtocol.maxActiveRequestCount() == 1)
        }
    }

    @Test
    func wrapsDownloadFailures() async throws {
        enum Failure: Error {
            case failed
        }

        let url = URL(string: "https://foundationex.test/failure")!
        try await withRegisteredMockURLProtocol(responses: [
            url: .init(data: Data(), error: Failure.failed)
        ]) {
            let downloader = ResourceDownloader<String>(maxConcurrentCount: 1)
            var didThrow = false

            do {
                _ = try await downloader.download(url: url) { data in
                    String(decoding: data, as: UTF8.self)
                }
            }
            catch {
                didThrow = true
            }

            #expect(didThrow)
            #expect(MockURLProtocol.requestCount(for: url) == 1)
        }
    }
}

private func withRegisteredMockURLProtocol<T>(
    responses: [URL: MockURLProtocol.MockResponse],
    operation: () async throws -> T
) async throws -> T {
    MockURLProtocol.reset(responses: responses)
    URLProtocol.registerClass(MockURLProtocol.self)
    defer {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset(responses: [:])
    }
    return try await operation()
}

// Instances add no mutable state. The loading task only reads URLProtocol's
// request/client and delivers callbacks; shared bookkeeping is locked below.
private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    struct MockResponse: Sendable {
        let data: Data
        let statusCode: Int
        let error: Error?
        let delay: UInt64

        init(data: Data, statusCode: Int = 200, error: Error? = nil, delay: UInt64 = 0) {
            self.data = data
            self.statusCode = statusCode
            self.error = error
            self.delay = delay
        }
    }

    // URLProtocol callbacks run outside actor isolation. All shared mock state is
    // private to this container and can only be accessed while holding its lock.
    private final class LockedState: @unchecked Sendable {
        struct Values {
            var responses: [URL: MockResponse] = [:]
            var requestCounts: [URL: Int] = [:]
            var activeRequestCount = 0
            var highestActiveRequestCount = 0
        }

        private let lock = NSLock()
        private var values = Values()

        func withLock<T: Sendable>(_ operation: (inout Values) -> T) -> T {
            lock.lock()
            defer {
                lock.unlock()
            }
            return operation(&values)
        }
    }

    private static let state = LockedState()

    static func reset(responses: [URL: MockResponse]) {
        state.withLock { state in
            state.responses = responses
            state.requestCounts = [:]
            state.activeRequestCount = 0
            state.highestActiveRequestCount = 0
        }
    }

    static func requestCount(for url: URL) -> Int {
        state.withLock { state in
            state.requestCounts[url, default: 0]
        }
    }

    static func maxActiveRequestCount() -> Int {
        state.withLock { state in
            state.highestActiveRequestCount
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return state.withLock { state in
            state.responses[url] != nil
        }
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            return
        }

        let response = Self.beginRequest(for: url)
        Task {
            defer {
                Self.finishRequest()
            }

            if response.delay > 0 {
                try? await Task.sleep(nanoseconds: response.delay)
            }

            if let error = response.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            let urlResponse = HTTPURLResponse(
                url: url,
                statusCode: response.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: response.data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}

    private static func beginRequest(for url: URL) -> MockResponse {
        state.withLock { state in
            state.requestCounts[url, default: 0] += 1
            state.activeRequestCount += 1
            state.highestActiveRequestCount = max(state.highestActiveRequestCount, state.activeRequestCount)
            return state.responses[url] ?? MockResponse(data: Data(), error: URLError(.unsupportedURL))
        }
    }

    private static func finishRequest() {
        state.withLock { state in
            state.activeRequestCount -= 1
        }
    }
}
