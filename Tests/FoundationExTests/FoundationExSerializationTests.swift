//
//  FoundationExSerializationTests.swift
//
//  Created by Codex on 4/11/26.
//

import Foundation
import Testing
import FoundationEx

@Suite
struct FoundationExSerializationTests {
    private struct Profile: Codable, Equatable, PropertyListRepresentableAsJSON {
        let name: String
        let score: Int
    }

    @Test
    func propertyListRepresentableAsSelfRoundTripsBasicValues() throws {
        let date = Date(timeIntervalSince1970: 123)

        #expect(Int.decode(7) == 7)
        #expect(String.decode("hello") == "hello")
        #expect(Double.decode(1.5) == 1.5)
        #expect(Bool.decode(true))
        #expect(Date.decode(date) == date)
        #expect(7.encode() == 7)
        #expect("hello".encode() == "hello")
    }

    @Test
    func arraysURLsAndOptionalsEncodeAndDecodePropertyListValues() throws {
        let url = URL(string: "https://example.com/path")!
        let encodedArray = [1, 2, 3].encode()
        let encodedURL = url.encode()
        let someURL: URL? = url
        let noURL: URL? = nil

        #expect(try [Int].decode(encodedArray) == [1, 2, 3])
        #expect(encodedURL == "https://example.com/path")
        #expect(try URL.decode(encodedURL) == url)
        #expect(try URL?.decode(someURL.encode()) == url)
        #expect(try URL?.decode(noURL.encode()) == nil)
        #expect(throwsError { _ = try URL.decode("http://exa mple.com") })
    }

    @Test
    func jsonRawValueRoundTripsCodableValues() throws {
        let profile = Profile(name: "Ada", score: 99)
        let raw = JSONRawValue(profile)
        let decodedRaw = try #require(JSONRawValue<Profile>(rawValue: raw.rawValue))

        #expect(decodedRaw.value == profile)
        #expect(try JSONRawValue<Profile>.decode(raw.encode()).value == profile)
        #expect(JSONRawValue<Profile>(rawValue: "{not json}") == nil)
    }

    @Test
    func propertyListRepresentableAsJSONUsesJSONStrings() throws {
        let profile = Profile(name: "Grace", score: 100)
        let encoded = profile.encode()
        let decoded = try Profile.decode(encoded)

        #expect(encoded.contains("Grace"))
        #expect(decoded == profile)
        #expect(throwsError { _ = try Profile.decode("not json") })
    }

    @Test
    func jsonSerializationPrettyPrintsValidJSONAndReportsInvalidData() throws {
        let object: [String: Any] = ["name": "Ada", "score": 99]
        let data = try JSONSerialization.data(withJSONObject: object)
        let pretty = JSONSerialization.stringValue(for: data)
        let prettyData = try #require(pretty.data(using: .utf8))
        let decoded = try JSONSerialization.jsonObject(with: prettyData) as? [String: Any]
        let error = JSONSerialization.stringValue(for: Data("not json".utf8))

        #expect(decoded?["name"] as? String == "Ada")
        #expect(decoded?["score"] as? Int == 99)
        #expect(pretty.contains("\n"))
        #expect(error.contains("<json error>"))
        #expect(error.contains("not json"))
    }

    @Test
    func testDefaultsStorageStoresAndRemovesValues() {
        let storage = TestDefaultsStorage()

        storage.set("value", forKey: "key")
        #expect(storage.object(forKey: "key") as? String == "value")

        storage.set(nil, forKey: "key")
        #expect(storage.object(forKey: "key") == nil)

        storage.set("value", forKey: "key")
        storage.removeObject(forKey: "key")
        #expect(storage.object(forKey: "key") == nil)
    }

    @Test
    func userDefaultsBackedReadsDefaultWritesValuesAndRemovesNilOptionals() {
        let storage = TestDefaultsStorage()
        var count = UserDefaultsBacked<Int>(key: "count", storage: storage, defaultValue: 7)
        var nickname = UserDefaultsBacked<String?>(key: "nickname", storage: storage, defaultValue: nil)

        #expect(count.wrappedValue == 7)
        count.wrappedValue = 42
        #expect(storage.object(forKey: "count") as? Int == 42)
        #expect(count.wrappedValue == 42)

        #expect(nickname.wrappedValue == nil)
        nickname.wrappedValue = "Blob"
        #expect(storage.object(forKey: "nickname") as? String == "Blob")
        #expect(nickname.wrappedValue == "Blob")

        nickname.wrappedValue = nil
        #expect(storage.object(forKey: "nickname") == nil)
        #expect(nickname.wrappedValue == nil)
    }

    @Test
    func userDefaultsBackedFallsBackWhenDecodingFails() {
        let storage = TestDefaultsStorage()
        let defaultURL = URL(string: "https://example.com/default")!
        var homepage = UserDefaultsBacked<URL>(key: "homepage", storage: storage, defaultValue: defaultURL)

        storage.set("http://exa mple.com", forKey: "homepage")

        #expect(homepage.wrappedValue == defaultURL)

        homepage.wrappedValue = URL(string: "https://example.com/home")!
        #expect(homepage.wrappedValue.absoluteString == "https://example.com/home")
    }
}
