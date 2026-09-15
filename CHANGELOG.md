# Changelog

## 1.1.0

- Require Swift 6.0 or later and build the package and tests in Swift 6 language mode.
- Require `Sendable` elements/results and an `@Sendable` transform in `Array.concurrentMap`.
- Require a `Sendable` result and an `@Sendable` processing closure in `ResourceDownloader`.
- Require `Sendable` values in `PropertyListError.invalidType` and `.invalidValue`.
- Make `NSRange.zero` a constant and mark imported-type conformances as `@retroactive`.
- Expand tests for concurrency, serialization, utilities, and resource downloads.

### Migration

The new concurrency requirements can require changes to callers. Add checked `Sendable`
conformances to values passed between tasks and avoid capturing mutable shared state in
`@Sendable` closures. Deployment targets are unchanged.
