//
//  FoundationExUtilitiesTests.swift
//
//  Created by Codex on 4/11/26.
//

import CoreGraphics
import Foundation
import MapKit
import os
import Testing
import FoundationEx

@Suite
struct FoundationExUtilitiesTests {
    @Test
    func timeIntervalFactoriesConvertCalendarUnitsToSeconds() {
        #expect(TimeInterval.minutes(3) == 180)
        #expect(TimeInterval.hours(2) == 7_200)
        #expect(TimeInterval.days(2) == 172_800)
    }

    @Test
    func doubleUnitConversionsUseExpectedConstants() {
        #expect(abs(1_609.344.metersToMiles - 1.0) < 0.000_001)
        #expect(abs(1.0.yearsToSeconds - 31_556_952.0) < 0.000_001)
        #expect(7_200.0.secondsToHours == 2)
    }

    @Test
    func optionalIdentifiableMirrorsWrappedID() {
        struct Item: Identifiable {
            let id: Int
        }

        let item: Item? = .init(id: 42)
        let missingItem: Item? = nil

        #expect(item.id == 42)
        #expect(missingItem.id == nil)
    }

    @Test
    func identifiableAsSelfAndIdentifiableValueExposeStableIDs() {
        enum Section: Hashable, IdentifiableAsSelf {
            case summary
        }

        let first = IdentifiableValue("alpha")
        let second = IdentifiableValue("alpha")

        #expect(Section.summary.id == .summary)
        #expect(first.value == "alpha")
        #expect(second.value == "alpha")
        #expect(first.id != second.id)
    }

    @Test
    func nsRangeZeroAndSequenceCoverEveryLocation() {
        #expect(NSRange.zero.location == 0)
        #expect(NSRange.zero.length == 0)
        #expect(Array(NSRange(location: 3, length: 4)) == [3, 4, 5, 6])
        #expect(Array(NSRange(location: 9, length: 0)).isEmpty)
    }

    @Test
    func dictionaryInsertReportsWhetherValueWasNew() {
        var values = ["a": 1]

        let existing = values.insert(key: "a", value: 2)
        let inserted = values.insert(key: "b", value: 3)

        #expect(existing.0 == false)
        #expect(existing.1 == 1)
        #expect(inserted.0 == true)
        #expect(inserted.1 == 3)
        #expect(values == ["a": 1, "b": 3])
    }

    @Test
    func staticStringURLInitializerBuildsURL() {
        let url = URL(staticString: "https://example.com/path?query=1")

        #expect(url.scheme == "https")
        #expect(url.host == "example.com")
        #expect(url.path == "/path")
        #expect(url.query == "query=1")
    }

    @Test
    func collectionSafeSubscriptAndIdentifiableValuesHandleBounds() {
        let values = ["a", "b", "c"]
        let identified = values.identifiableValues()

        #expect(values[safe: values.startIndex] == "a")
        #expect(values[safe: values.endIndex] == nil)
        #expect(identified.map(\.value) == values)
        #expect(Set(identified.map(\.id)).count == values.count)
    }

    @Test
    func comparableClampedHandlesValuesInsideAndOutsideRange() {
        #expect(5.clamped(1, 10) == 5)
        #expect((-3).clamped(1, 10) == 1)
        #expect(17.clamped(1, 10) == 10)
    }

    @Test
    func dateRangeChecksAreInclusive() {
        let start = Date(timeIntervalSince1970: 100)
        let middle = Date(timeIntervalSince1970: 150)
        let end = Date(timeIntervalSince1970: 200)
        let after = Date(timeIntervalSince1970: 201)

        #expect(start.isInRange(min: start, max: end))
        #expect(middle.isInRange((start, end)))
        #expect(end.isInRange(min: start, max: end))
        #expect(!after.isInRange(min: start, max: end))
        #expect(Date(timeIntervalSinceNow: -1).timeIntervalToNow >= 0)
    }

    @Test
    func uniqueElementsKeepsFirstOccurrenceOrder() {
        #expect([3, 1, 3, 2, 1, 4].uniqueElements() == [3, 1, 2, 4])
        #expect([Int]().uniqueElements().isEmpty)
    }

    @Test
    func erasedSequencesMapAndFilterLazily() throws {
        enum Stop: Error {
            case now
        }

        let filtered = AnySequence([1, 2, 3, 4, 5, 6])
            .filterAsSequence { $0.isMultiple(of: 2) }
        let mapped = try AnySequence([1, 2, 3, 4])
            .mapAsSequence { value -> Int in
                if value == 4 {
                    throw Stop.now
                }
                return value * 10
            }

        #expect(Array(filtered) == [2, 4, 6])
        #expect(Array(mapped) == [10, 20, 30])
    }

    @Test
    func asyncTaskValueExposesOnlyCurrentStatePayload() {
        enum Failure: Error, Equatable {
            case failed
        }

        var value = AsyncTaskValue<Int, Failure>.success(7)
        #expect(value.value == 7)
        #expect(value.error == nil)
        #expect(!value.isInProgress)

        value = .failure(.failed)
        #expect(value.value == nil)
        #expect(value.error == .failed)
        value.resetIfError()
        #expect(value.value == nil)
        #expect(value.error == nil)

        value = .inProgress
        #expect(value.isInProgress)
        value.resetIfError()
        #expect(value.isInProgress)
    }

    @Test
    func cacheSupportsMethodsAndSubscriptRemoval() {
        let cache = Cache<String, Int>()

        cache.insert(1, forKey: "one")
        #expect(cache.value(forKey: "one") == 1)

        cache["two"] = 2
        #expect(cache["two"] == 2)

        cache.removeValue(forKey: "one")
        #expect(cache.value(forKey: "one") == nil)

        cache["two"] = nil
        #expect(cache["two"] == nil)

        cache.insert(3, forKey: "three")
        cache.removeAll()
        #expect(cache.value(forKey: "three") == nil)
    }

    @Test
    func equatableNoOpAlwaysComparesEqual() {
        let first = EquatableNoOp(wrappedValue: 1)
        let second = EquatableNoOp(wrappedValue: 99)

        #expect(first == second)
    }

    @Test
    func hexColorsParseRGBAndRGBAForms() throws {
        let short = try "336699".parseAsHexColor()
        let opaque = try "#336699".parseAsHexColor()
        let translucent = try "#33669980".parseAsHexColor()

        #expect(short.r == CGFloat(0x33) / 255.0)
        #expect(short.g == CGFloat(0x66) / 255.0)
        #expect(short.b == CGFloat(0x99) / 255.0)
        #expect(short.a == 1)
        #expect(opaque == short)
        #expect(translucent.r == short.r)
        #expect(translucent.g == short.g)
        #expect(translucent.b == short.b)
        #expect(translucent.a == CGFloat(0x80) / 255.0)
    }

    @Test
    func hexColorParserRejectsMalformedInput() {
        #expect(throwsError { _ = try "12345".parseAsHexColor() })
        #expect(throwsError { _ = try "#3366zz".parseAsHexColor() })
        #expect(throwsError { _ = try "#3366990011".parseAsHexColor() })
    }

    @Test
    func coordinateRegionUsesMilesForLatitudeAndLongitudeSpan() {
        let coordinate = CLLocationCoordinate2D(latitude: 60, longitude: -30)
        let region = coordinate.region(radius: 69)

        #expect(region.center.latitude == 60)
        #expect(region.center.longitude == -30)
        #expect(abs(region.span.latitudeDelta - 1) < 0.000_001)
        #expect(abs(region.span.longitudeDelta - 2) < 0.000_001)
    }

    @Test
    func globalHelpersExposeTestingLookupAndObjectAddress() {
        final class Box {}

        let box = Box()
        let firstAddress = address(of: box)
        let secondAddress = address(of: box)

        #expect(isTesting() == (NSClassFromString("XCTest") != nil))
        #expect(firstAddress == secondAddress)
        #expect(firstAddress.contains("0x"))
    }

    @Test
    func loggerErrorOverloadAcceptsErrorValues() {
        enum SampleError: Error {
            case failed
        }

        let logger = Logger(subsystem: "FoundationExTests", category: "Utilities")
        logger.error(message: "sample", SampleError.failed)
    }

    @Test
    func controlCharacterIsZeroWidthSpace() {
        #expect(Character.control == "\u{200B}")
    }
}

func throwsError(_ operation: () throws -> Void) -> Bool {
    do {
        try operation()
        return false
    }
    catch {
        return true
    }
}
