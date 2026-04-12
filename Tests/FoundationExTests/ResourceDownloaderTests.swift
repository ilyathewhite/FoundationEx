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

private final class MockURLProtocol: URLProtocol {
    struct MockResponse {
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

    private static let lock = NSLock()
    private static var responses: [URL: MockResponse] = [:]
    private static var requestCounts: [URL: Int] = [:]
    private static var activeRequestCount = 0
    private static var highestActiveRequestCount = 0

    static func reset(responses: [URL: MockResponse]) {
        locked {
            Self.responses = responses
            requestCounts = [:]
            activeRequestCount = 0
            highestActiveRequestCount = 0
        }
    }

    static func requestCount(for url: URL) -> Int {
        locked {
            requestCounts[url, default: 0]
        }
    }

    static func maxActiveRequestCount() -> Int {
        locked {
            highestActiveRequestCount
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return locked {
            responses[url] != nil
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
        locked {
            requestCounts[url, default: 0] += 1
            activeRequestCount += 1
            highestActiveRequestCount = max(highestActiveRequestCount, activeRequestCount)
            return responses[url] ?? MockResponse(data: Data(), error: URLError(.unsupportedURL))
        }
    }

    private static func finishRequest() {
        locked {
            activeRequestCount -= 1
        }
    }

    private static func locked<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer {
            lock.unlock()
        }
        return operation()
    }
}
