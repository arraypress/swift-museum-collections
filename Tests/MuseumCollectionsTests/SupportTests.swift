//
//  SupportTests.swift
//  MuseumCollectionsTests
//
//  Created by David Sherlock on 2026.
//
//  The pure parts, without a network: ids, URLs, mapping, merging, sizing.
//

import Foundation
import XCTest
@testable import MuseumCollections

final class SupportTests: XCTestCase {

    func testIdentifiersParseBothPrefixesAndPageURLs() {
        XCTAssertEqual(ArtworkID("met:436524"), ArtworkID(museum: .met, number: 436524))
        XCTAssertEqual(ArtworkID("AIC:27992"), ArtworkID(museum: .aic, number: 27992), "prefix is case-insensitive")
        XCTAssertEqual(ArtworkID("  aic:27992\n"), ArtworkID(museum: .aic, number: 27992))
        XCTAssertEqual(ArtworkID("https://www.metmuseum.org/art/collection/search/436524"), ArtworkID(museum: .met, number: 436524))
        XCTAssertEqual(ArtworkID("https://www.artic.edu/artworks/27992/a-sunday-on-la-grande-jatte-1884"),
                       ArtworkID(museum: .aic, number: 27992))
        XCTAssertNil(ArtworkID("436524"), "a bare number names no museum")
        XCTAssertNil(ArtworkID("louvre:1"))
        XCTAssertNil(ArtworkID("met:"))
        XCTAssertNil(ArtworkID("met:-4"))
        XCTAssertNil(ArtworkID("met:12x"))
        XCTAssertNil(ArtworkID("https://example.com/artworks/5"))
        XCTAssertEqual(ArtworkID(museum: .met, number: 436524).description, "met:436524")
    }

    func testMetSearchURLCarriesOnlyFiltersItHonours() {
        let url = MuseumURLs.metSearch(text: "sunflowers", imagesOnly: true, years: -500 ... 1500, department: 11,
                                       limit: 50, offset: 20)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        XCTAssertTrue(url.path.hasSuffix("/v1.1/search"))
        XCTAssertEqual(value("q"), "sunflowers")
        XCTAssertEqual(value("hasImages"), "true")
        XCTAssertEqual(value("dateBegin"), "-500", "BCE is negative")
        XCTAssertEqual(value("dateEnd"), "1500")
        XCTAssertEqual(value("departmentId"), "11")
        XCTAssertEqual(value("limit"), "50")
        XCTAssertEqual(value("offset"), "20")
        XCTAssertNil(value("isPublicDomain"), "the Met ignores it; never pretend it filters")
    }

    func testChicagoSearchParamsAreOneJSONObject() throws {
        let url = MuseumURLs.aicSearch(text: "cats", publicDomainOnly: true, imagesOnly: true, years: 1800 ... 1900,
                                       limit: 5, offset: 10)
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!.first { $0.name == "params" }!.value!
        let json = try JSONSerialization.jsonObject(with: Data(params.utf8)) as! [String: Any]
        XCTAssertEqual(json["q"] as? String, "cats")
        XCTAssertEqual(json["limit"] as? Int, 5)
        XCTAssertEqual(json["from"] as? Int, 10)
        let filters = ((json["query"] as! [String: Any])["bool"] as! [String: Any])["filter"] as! [[String: Any]]
        XCTAssertEqual(filters.count, 4, "public domain, image, two date bounds")
        let plain = MuseumURLs.aicSearch(text: "cats", publicDomainOnly: false, imagesOnly: false, years: nil, limit: 5, offset: 0)
        XCTAssertFalse(plain.absoluteString.contains("query"), "no filters, no query clause")
    }

    func testIIIFURLsAndSizingRespectTheRestrictedCap() {
        let base = MuseumURLs.iiifBase(imageID: "2d484387-2509-5e8e-2c43-22f9981972eb")!
        XCTAssertEqual(MuseumURLs.iiif(base: base, width: 1200).absoluteString,
                       "https://www.artic.edu/iiif/2/2d484387-2509-5e8e-2c43-22f9981972eb/full/1200,/0/default.jpg")
        let open = ArtworkImage(preview: base, full: base, iiifBase: base, maximumWidth: nil)
        XCTAssertTrue(open.url(width: 2000).absoluteString.contains("/full/2000,/"))
        let restricted = ArtworkImage(preview: base, full: base, iiifBase: base, maximumWidth: 843)
        XCTAssertTrue(restricted.url(width: 2000).absoluteString.contains("/full/843,/"), "capped where the server would redirect")
        XCTAssertTrue(restricted.url(width: 400).absoluteString.contains("/full/400,/"))
        let preview = URL(string: "https://images.metmuseum.org/web-large/a.jpg")!
        let full = URL(string: "https://images.metmuseum.org/original/a.jpg")!
        let met = ArtworkImage(preview: preview, full: full, iiifBase: nil, maximumWidth: nil)
        XCTAssertEqual(met.url(width: 600), preview)
        XCTAssertEqual(met.url(width: 3000), full)
        XCTAssertEqual(met.url(width: nil), full)
    }

    func testMetEmptyStringsBecomeNilAndAWorkWithoutImagesHasNone() throws {
        let json = #"{"objectID":1,"title":"","artistDisplayName":"","objectDate":"ca. 1500–1450 B.C.","objectBeginDate":-1450,"objectEndDate":-1500,"isPublicDomain":false,"primaryImage":"","primaryImageSmall":"","objectURL":""}"#
        let artwork = ArtworkMapping.met(try JSONDecoder().decode(MetObjectResponse.self, from: Data(json.utf8)))
        XCTAssertEqual(artwork.title, "Untitled")
        XCTAssertNil(artwork.artist)
        XCTAssertNil(artwork.image, "empty-string image fields are no image")
        XCTAssertEqual(artwork.years, -1500 ... -1450, "reversed BCE ends are put in order")
        XCTAssertEqual(artwork.url.absoluteString, "https://www.metmuseum.org/art/collection/search/1")
    }

    func testChicagoArtistDisplaySplitsNameFromDetails() throws {
        let json = #"{"_score":120.5,"id":27992,"title":"A Sunday on La Grande Jatte — 1884","artist_title":"Georges Seurat","artist_display":"Georges Seurat\nFrench, 1859–1891","date_start":1884,"date_end":1886,"is_public_domain":true,"image_id":"abc"}"#
        let artwork = ArtworkMapping.aic(try JSONDecoder().decode(AICArtworkResponse.self, from: Data(json.utf8)))
        XCTAssertEqual(artwork.artist, "Georges Seurat")
        XCTAssertEqual(artwork.artistDetails, "French, 1859–1891")
        XCTAssertEqual(artwork.image?.maximumWidth, nil)
        XCTAssertTrue(artwork.image!.full.absoluteString.contains("/full/3000,/"))
        let restricted = #"{"id":2,"artist_display":"Frida Kahlo\nMexican, 1907–1954","is_public_domain":false,"image_id":"x"}"#
        let other = ArtworkMapping.aic(try JSONDecoder().decode(AICArtworkResponse.self, from: Data(restricted.utf8)))
        XCTAssertEqual(other.artist, "Frida Kahlo", "first line when artist_title is missing")
        XCTAssertEqual(other.image?.maximumWidth, 843)
        XCTAssertTrue(other.image!.full.absoluteString.contains("/full/843,/"))
    }

    func testChicagoArtistDisplayInBothShapes() {
        XCTAssertEqual(ArtworkMapping.artist(display: "Georges Seurat (French, 1859–1891)", title: "Georges Seurat").details,
                       "French, 1859–1891")
        let hokusai = ArtworkMapping.artist(display: "Katsushika Hokusai 葛飾 北斎 \nJapanese, 1760-1849", title: nil)
        XCTAssertEqual(hokusai.name, "Katsushika Hokusai 葛飾 北斎")
        XCTAssertEqual(hokusai.details, "Japanese, 1760-1849")
        XCTAssertEqual(ArtworkMapping.artist(display: "Unknown Artist", title: nil).name, "Unknown Artist")
        XCTAssertNil(ArtworkMapping.artist(display: "Unknown Artist", title: nil).details)
        XCTAssertNil(ArtworkMapping.artist(display: nil, title: nil).name)
    }

    func testRelevanceLineDropsChicagosFiller() {
        XCTAssertTrue(Ranking.isRelevant(score: 5.2))
        XCTAssertFalse(Ranking.isRelevant(score: 0.00001))
        XCTAssertFalse(Ranking.isRelevant(score: nil))
    }

    func testInterleaveAlternatesFillsFromTheLongerListAndCountsUse() {
        let (merged, used) = Ranking.interleave([[1, 3, 5, 7], [2, 4]], limit: 5)
        XCTAssertEqual(merged, [1, 2, 3, 4, 5])
        XCTAssertEqual(used, [3, 2])
        XCTAssertEqual(Ranking.interleave([[Int](), [1, 2]], limit: 10).merged, [1, 2])
        XCTAssertEqual(Ranking.interleave([[1, 2], [3]], limit: 1).used, [1, 0])
    }

    func testNextOffsetResumesAtTheFirstUnshownHit() {
        func ranked(_ position: Int) -> RankedArtwork {
            let json = #"{"id":\#(position)}"#
            return RankedArtwork(artwork: ArtworkMapping.aic(try! JSONDecoder().decode(AICArtworkResponse.self, from: Data(json.utf8))),
                                 position: position)
        }
        let page = MuseumPage(museum: .met, hits: [ranked(0), ranked(4), ranked(9)], scannedTo: 12, hasMore: true, total: 40)
        XCTAssertEqual(Ranking.nextOffset(page, used: 1), 4)
        XCTAssertEqual(Ranking.nextOffset(page, used: 3), 12)
        let done = MuseumPage(museum: .met, hits: [ranked(0)], scannedTo: 3, hasMore: false, total: 3)
        XCTAssertNil(Ranking.nextOffset(done, used: 1))
    }

    func testChicagoHostsGetTheirHeaderAndOthersDoNot() {
        let image = RequestHeaders.request(for: URL(string: "https://www.artic.edu/iiif/2/x/full/843,/0/default.jpg")!)
        XCTAssertNotNil(image.value(forHTTPHeaderField: "AIC-User-Agent"), "the IIIF server refuses without it")
        XCTAssertNotNil(RequestHeaders.request(for: URL(string: "https://api.artic.edu/api/v1/artworks/1")!)
            .value(forHTTPHeaderField: "AIC-User-Agent"))
        let met = RequestHeaders.request(for: URL(string: "https://collectionapi.metmuseum.org/x")!)
        XCTAssertNil(met.value(forHTTPHeaderField: "AIC-User-Agent"))
        XCTAssertNil(RequestHeaders.request(for: URL(string: "https://notartic.edu/x")!).value(forHTTPHeaderField: "AIC-User-Agent"))
        XCTAssertNotNil(met.value(forHTTPHeaderField: "User-Agent"))
    }

    func testStatusesMapOntoErrors() {
        let id = ArtworkID(museum: .met, number: 1)
        XCTAssertNil(HTTPStatus.error(for: 200, museum: .met, id: id))
        XCTAssertEqual(HTTPStatus.error(for: 404, museum: .met, id: id), .notFound(id))
        XCTAssertEqual(HTTPStatus.error(for: 404, museum: .met, id: nil), .http(.met, 404))
        XCTAssertEqual(HTTPStatus.error(for: 429, museum: .aic, id: nil), .rateLimited(.aic))
        XCTAssertEqual(HTTPStatus.error(for: 503, museum: .aic, id: nil), .http(.aic, 503))
    }

    func testQueryRulesRefuseWhatCannotBeSent() {
        XCTAssertThrowsError(try QueryRules.validate(ArtworkQuery("   ")))
        XCTAssertThrowsError(try QueryRules.validate(ArtworkQuery("x", limit: 0)))
        XCTAssertThrowsError(try QueryRules.validate(ArtworkQuery("x", limit: 101)))
        XCTAssertThrowsError(try QueryRules.validate(ArtworkQuery("x", offset: -1)))
        XCTAssertThrowsError(try QueryRules.validateChicago(ArtworkQuery("x", limit: 10, offset: 9_995)))
        XCTAssertNoThrow(try QueryRules.validateChicago(ArtworkQuery("x", limit: 10, offset: 9_990)))
        XCTAssertEqual(QueryRules.metReadCap(limit: 10), 50)
        XCTAssertEqual(QueryRules.metReadCap(limit: 100), 200)
    }

    func testDownloadsIntoAFolderAreNamedByID() {
        let folder = URL(fileURLWithPath: "/tmp/art")
        let id = ArtworkID(museum: .aic, number: 27992)
        XCTAssertEqual(ImageFiles.file(at: folder, isDirectory: true, id: id, contentType: "image/jpeg").lastPathComponent, "aic-27992.jpg")
        XCTAssertEqual(ImageFiles.file(at: folder, isDirectory: true, id: id, contentType: "image/png; charset=binary").pathExtension, "png")
        XCTAssertEqual(ImageFiles.file(at: folder, isDirectory: false, id: id, contentType: "image/jpeg"), folder)
    }

    /// How many transforms run at once.
    actor Gauge {
        private(set) var now = 0, peak = 0
        func enter() { now += 1; peak = max(peak, now) }
        func leave() { now -= 1 }
    }

    func testConcurrencyCapsWorkInFlightAndStopsOnTheFirstError() async throws {
        let gauge = Gauge()
        _ = try await Concurrency.map(Array(0 ..< 40), width: 8) { n in
            await gauge.enter()
            try await Task.sleep(nanoseconds: 2_000_000)
            await gauge.leave()
            return n
        }
        let peak = await gauge.peak
        XCTAssertLessThanOrEqual(peak, 8)
        XCTAssertGreaterThan(peak, 1, "it does run in parallel")

        struct Boom: Error {}
        do {
            _ = try await Concurrency.map(Array(0 ..< 40), width: 4) { n in
                if n == 3 { throw Boom() }
                try await Task.sleep(nanoseconds: 50_000_000)
                return n
            }
            XCTFail("the error must surface")
        } catch is Boom {}
        XCTAssertEqual(ErrorMapping.museumError(CancellationError()), .cancelled)
    }

    func testConcurrencyKeepsOrder() async throws {
        let out = try await Concurrency.map(Array(0 ..< 50), width: 8) { n in
            try await Task.sleep(nanoseconds: UInt64((50 - n) * 100_000))
            return n * 2
        }
        XCTAssertEqual(out, (0 ..< 50).map { $0 * 2 })
    }
}
