//
//  ClientTests.swift
//  MuseumCollectionsTests
//
//  Created by David Sherlock on 2026.
//
//  The clients against a canned transport: merging, skipped 404s, the
//  public-domain refusal, partial failure.
//

import Foundation
import XCTest
@testable import MuseumCollections

final class ClientTests: XCTestCase {

    /// Canned answers by URL substring; anything else is a 404.
    final class Canned: @unchecked Sendable {
        let lock = NSLock()
        var routes: [(String, Int, String, String)] = []
        var seen: [URLRequest] = []

        func add(_ match: String, _ body: String, status: Int = 200, type: String = "application/json") {
            routes.append((match, status, body, type))
        }

        func record(_ request: URLRequest) {
            lock.lock(); seen.append(request); lock.unlock()
        }

        var transport: Transport {
            { request in
                self.record(request)
                let url = request.url!.absoluteString
                let route = self.routes.first { url.contains($0.0) }
                let response = HTTPURLResponse(url: request.url!, statusCode: route?.1 ?? 404, httpVersion: nil,
                                               headerFields: ["Content-Type": route?.3 ?? "application/json"])!
                return (Data((route?.2 ?? "{}").utf8), response)
            }
        }
    }

    func metObject(_ id: Int, publicDomain: Bool) -> String {
        let image = publicDomain ? "https://images.metmuseum.org/\(id).jpg" : ""
        return #"{"objectID":\#(id),"title":"Met \#(id)","isPublicDomain":\#(publicDomain),"primaryImage":"\#(image)","primaryImageSmall":"\#(image)"}"#
    }

    func testMetSearchSkipsUnknownIdsAndFiltersPublicDomainItself() async throws {
        let canned = Canned()
        canned.add("/v1.1/search", #"{"total":5,"objectIDs":[1,2,3,4,5]}"#)
        canned.add("/objects/1", metObject(1, publicDomain: true))
        canned.add("/objects/2", metObject(2, publicDomain: false))
        // 3 is unknown: 404
        canned.add("/objects/4", metObject(4, publicDomain: true))
        canned.add("/objects/5", metObject(5, publicDomain: true))
        let met = MetMuseum(transport: canned.transport)
        let results = try await met.search(ArtworkQuery("x", museums: [.met], publicDomainOnly: true, limit: 2))
        XCTAssertEqual(results.artworks.map(\.id.number), [1, 4])
        XCTAssertEqual(results.metMatches, 5)
        XCTAssertEqual(results.next[.met], 4, "continues after object 4, at position 4")
    }

    func testMetSearchWithNoHitsIsEmptyNotAnError() async throws {
        let canned = Canned()
        canned.add("/v1.1/search", #"{"total":0,"objectIDs":null}"#)
        let results = try await MetMuseum(transport: canned.transport).search(ArtworkQuery("zzqq"))
        XCTAssertTrue(results.artworks.isEmpty)
        XCTAssertTrue(results.next.isEmpty)
    }

    func testCombinedSearchInterleavesAndReportsAPartialFailure() async throws {
        let canned = Canned()
        canned.add("/v1.1/search", #"{"total":2,"objectIDs":[1,2]}"#)
        canned.add("/objects/1", metObject(1, publicDomain: true))
        canned.add("/objects/2", metObject(2, publicDomain: true))
        canned.add("api.artic.edu/api/v1/artworks/search",
                   #"{"data":[{"_score":40,"id":10,"title":"A","is_public_domain":true,"image_id":"i"},{"_score":0.00001,"id":11,"title":"filler"}]}"#)
        let both = try await MuseumCollections(transport: canned.transport).search(ArtworkQuery("x", limit: 10))
        XCTAssertEqual(both.artworks.map(\.id.description), ["met:1", "aic:10", "met:2"], "filler below the line is dropped")
        XCTAssertTrue(both.next.isEmpty)

        let broken = Canned()
        broken.add("/v1.1/search", "", status: 503)
        broken.add("api.artic.edu/api/v1/artworks/search", #"{"data":[{"_score":40,"id":10,"image_id":"i"}]}"#)
        let partial = try await MuseumCollections(transport: broken.transport).search(ArtworkQuery("x"))
        XCTAssertEqual(partial.artworks.map(\.id.description), ["aic:10"])
        XCTAssertNotNil(partial.failures[.met])

        let dead = Canned()
        do {
            _ = try await MuseumCollections(transport: dead.transport).search(ArtworkQuery("x"))
            XCTFail("every museum failed")
        } catch let error as MuseumError {
            XCTAssertEqual(error, .http(.met, 404))
        }
    }

    func testDepartmentSearchAsksOnlyTheMet() async throws {
        let canned = Canned()
        canned.add("/v1.1/search", #"{"total":0,"objectIDs":null}"#)
        _ = try await MuseumCollections(transport: canned.transport).search(ArtworkQuery("x", metDepartment: 11))
        XCTAssertFalse(canned.seen.contains { $0.url!.host!.contains("artic") })
    }

    func testDownloadRefusesRestrictedWorksUnlessForced() async throws {
        let canned = Canned()
        canned.add("api.artic.edu/api/v1/artworks/2", #"{"data":{"id":2,"is_public_domain":false,"image_id":"r"}}"#)
        canned.add("/iiif/2/r/full/843,", "JPEGBYTES", type: "image/jpeg")
        let museums = MuseumCollections(transport: canned.transport)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let id = ArtworkID(museum: .aic, number: 2)
        do {
            _ = try await museums.download(id, to: folder)
            XCTFail("restricted works are not downloaded by default")
        } catch let error as MuseumError {
            XCTAssertEqual(error, .notPublicDomain(id))
        }
        let saved = try await museums.download(id, to: folder, width: 4000, allowRestricted: true)
        XCTAssertEqual(saved.file.lastPathComponent, "aic-2.jpg")
        XCTAssertEqual(saved.bytes, 9)
        XCTAssertTrue(saved.source.absoluteString.contains("/full/843,/"), "never past the museum's cap")
        XCTAssertFalse(saved.isPublicDomain)
        XCTAssertNotNil(canned.seen.last?.value(forHTTPHeaderField: "AIC-User-Agent"))
    }

    func testDownloadOfAWorkWithoutAnImageSaysSo() async throws {
        let canned = Canned()
        canned.add("/objects/7", metObject(7, publicDomain: false))
        let id = ArtworkID(museum: .met, number: 7)
        do {
            _ = try await MuseumCollections(transport: canned.transport).download(id, to: URL(fileURLWithPath: "/tmp/x.jpg"))
            XCTFail("no image")
        } catch let error as MuseumError {
            XCTAssertEqual(error, .noImage(id))
        }
    }

    func testUnknownIdIsNotFound() async throws {
        let id = ArtworkID(museum: .met, number: 999_999_999)
        do {
            _ = try await MuseumCollections(transport: Canned().transport).artwork(id)
            XCTFail("unknown")
        } catch let error as MuseumError {
            XCTAssertEqual(error, .notFound(id))
        }
    }

    func testAPageThatIsNotAnImageIsRefused() async throws {
        let canned = Canned()
        canned.add("/objects/8", metObject(8, publicDomain: true))
        canned.add("images.metmuseum.org", "<html>", type: "text/html")
        do {
            _ = try await MuseumCollections(transport: canned.transport)
                .download(ArtworkID(museum: .met, number: 8), to: URL(fileURLWithPath: "/tmp/never.jpg"))
            XCTFail("html is not an image")
        } catch let error as MuseumError {
            guard case .malformed = error else { return XCTFail("\(error)") }
        }
    }
}
