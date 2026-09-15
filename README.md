# FoundationEx

Provides convenience APIs for some common tasks related to Foundation.

Requires Swift 6.0 or later and builds in Swift 6 language mode.

## Swift 6 migration

- `Array.concurrentMap` requires `Sendable` elements and results, and an `@Sendable` transform.
- `ResourceDownloader` requires a `Sendable` result and an `@Sendable` processing closure.
- `PropertyListError` accepts `Sendable` values in its `invalidType` and `invalidValue` cases.
- `NSRange.zero` is now a constant.
