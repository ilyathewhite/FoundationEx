//
//  FoundationExAsyncTests.swift
//
//  Created by Codex on 4/11/26.
//

import Foundation
import Testing
import FoundationEx

@Suite
struct FoundationExAsyncTests {
    @Test
    @MainActor
    func supersededTaskBurstsRemoveAllCompletedBookkeeping() async throws {
        let manager = TaskManager()
        var executed: [Int] = []
        for burst in 0..<3 {
            let tasks = (0..<1_000).map { index in
                manager.addTask(cancellingPreviousWithKey: "search") { executed.append(index) }
            }
            for task in tasks { await task.value }
            #expect(executed == Array(repeating: 999, count: burst + 1))
            let entries = try #require(Mirror(reflecting: manager).children.first { $0.label == "tasks" })
            #expect(Mirror(reflecting: entries.value).children.isEmpty)
            let keys = try #require(Mirror(reflecting: manager).children.first { $0.label == "inFlightTaskIDs" })
            #expect(Mirror(reflecting: keys.value).children.isEmpty)
        }
        let cancelled = manager.addTask(cancellingPreviousWithKey: "search") {}
        manager.cancelAllTasks()
        await cancelled.value
        let unkeyed = manager.addTask {}
        await unkeyed.value
        let entries = try #require(Mirror(reflecting: manager).children.first { $0.label == "tasks" })
        #expect(Mirror(reflecting: entries.value).children.isEmpty)
    }

    @Test
    func erasedAsyncSequenceYieldsValuesFromUnderlyingSequence() async throws {
        let stream = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }

        let values = try await collect(stream.eraseToAnyAsyncSequence())

        #expect(values == [1, 2, 3])
    }

    @Test
    func erasedAsyncSequencePropagatesThrownErrors() async throws {
        enum Failure: Error {
            case failed
        }

        let stream = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(1)
            continuation.finish(throwing: Failure.failed)
        }
        var iterator = stream.eraseToAnyAsyncSequence().makeAsyncIterator()

        #expect(try await iterator.next() == 1)
        do {
            _ = try await iterator.next()
            #expect(Bool(false))
        }
        catch {
            #expect(error is Failure)
        }
    }

    @Test
    func semaphoreLimitsConcurrentAccess() async {
        let semaphore = AsyncSemaphore(maxCount: 2)
        let tracker = ConcurrencyTracker()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    await semaphore.aquire()
                    await tracker.enter()
                    try? await Task.sleep(nanoseconds: 10_000_000)
                    await tracker.leave()
                    await semaphore.release()
                }
            }
        }

        #expect(await tracker.maximumActiveCount() == 2)
    }

    @Test
    @MainActor
    func taskManagerCancelsPreviousTaskWithSameKey() async {
        let manager = TaskManager()
        let first = manager.addTask(cancellingPreviousWithKey: "search") {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        await Task.yield()

        let second = manager.addTask(cancellingPreviousWithKey: "search") {}

        #expect(first.isCancelled)
        await second.value
    }

    @Test
    @MainActor
    func taskManagerCancelAllCancelsInFlightTasks() async {
        let manager = TaskManager()
        let task = manager.addTask {
            while !Task.isCancelled {
                await Task.yield()
            }
        }

        await Task.yield()
        manager.cancelAllTasks()
        await task.value

        #expect(task.isCancelled)
    }
}

private actor ConcurrencyTracker {
    private var activeCount = 0
    private var maxActiveCount = 0

    func enter() {
        activeCount += 1
        maxActiveCount = max(maxActiveCount, activeCount)
    }

    func leave() {
        activeCount -= 1
    }

    func maximumActiveCount() -> Int {
        maxActiveCount
    }
}

private func collect<S: AsyncSequence>(_ sequence: S) async throws -> [S.Element] {
    var iterator = sequence.makeAsyncIterator()
    var values: [S.Element] = []
    while let value = try await iterator.next() {
        values.append(value)
    }
    return values
}
