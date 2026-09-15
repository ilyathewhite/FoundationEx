# FoundationEx

Provides convenience APIs for some common tasks related to Foundation.

Requires Swift 6.0 or later and builds in Swift 6 language mode.

## Installation

```swift
.package(url: "https://github.com/ilyathewhite/FoundationEx.git", from: "1.1.0")
```

See the [changelog](CHANGELOG.md) for release details.

## Swift 6 migration

- `Array.concurrentMap` requires `Sendable` elements and results, and an `@Sendable` transform.
- `ResourceDownloader` requires a `Sendable` result and an `@Sendable` processing closure.
- `PropertyListError` accepts `Sendable` values in its `invalidType` and `invalidValue` cases.
- `NSRange.zero` is now a constant.
