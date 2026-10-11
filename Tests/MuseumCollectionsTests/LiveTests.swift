//
//  LiveTests.swift
//  MuseumCollectionsTests
//
//  Created by David Sherlock on 2026.
//
//  Against the real museums. A refusal — offline, rate-limited, a 5xx — skips
//  rather than fails: these check the APIs' shapes, not their uptime.
//

import Foundation
import XCTest
@testable import MuseumCollections

final class LiveTests: XCTestCase {

    let museums = MuseumCollections()

    /// Runs `body`, skipping when a museum refuses.
    func live<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch let error as MuseumError {
            switch error {
            case .network, .rateLimited, .http, .cancelled: throw XCTSkip("museum refused: \(error.localizedDescription)")
            default: throw error
            }
        }
    }

    func testKnownWorksFromBothMuseums() async throws {
        let wheat = try await live { try await museums.artwork(ArtworkID("met:436535")!) }
        XCTAssertEqual(wheat.artist, "Vincent van Gogh")
        XCTAssertTrue(wheat.isPublicDomain)
        XCTAssertNotNil(wheat.image)
        let jatte = try await live { try await museums.artwork(ArtworkID("aic:27992")!) }
        XCTAssertEqual(jatte.artist, "Georges Seurat")
        XCTAssertNotNil(jatte.image?.iiifBase)
    }

    func testCombinedPublicDomainSearchReturnsBothMuseums() async throws {
        let results = try await live { try await museums.search(ArtworkQuery("sunflowers", publicDomainOnly: true, limit: 6)) }
        if let failure = results.failures.values.first { throw XCTSkip("a museum refused: \(failure)") }
        XCTAssertEqual(results.artworks.count, 6)
        XCTAssertTrue(results.artworks.allSatisfy(\.isPublicDomain))
        XCTAssertEqual(Set(results.artworks.map(\.id.museum)), [.met, .aic])
        XCTAssertNotNil(results.metMatches)
    }

    func testNonsenseFindsNothingAnywhere() async throws {
        let results = try await live { try await museums.search(ArtworkQuery("zzqqxxnothingatall")) }
        XCTAssertTrue(results.artworks.isEmpty, "Chicago's filler must not leak through")
        XCTAssertTrue(results.next.isEmpty)
    }

    func testUnknownIdsAreNotFound() async throws {
        for text in ["met:999999999", "aic:999999999"] {
            let id = ArtworkID(text)!
            do {
                _ = try await live { try await museums.artwork(id) }
                XCTFail("\(text) exists?")
            } catch let error as MuseumError {
                XCTAssertEqual(error, .notFound(id))
            }
        }
    }

    func testChicagoImageDownloadsWithItsHeader() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("aic-\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: file) }
        let saved = try await live { try await museums.download(ArtworkID("aic:27992")!, to: file, width: 200) }
        XCTAssertGreaterThan(saved.bytes, 1_000)
        XCTAssertEqual(try Data(contentsOf: file).prefix(2), Data([0xFF, 0xD8]), "a JPEG")
    }
}
