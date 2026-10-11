//
//  MetMuseum.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  The Metropolitan Museum of Art's open-access API: keyless, about 490,000
//  objects. Its search returns ids only, so results are read one object at a time,
//  eight at once.
//

import Foundation

/// The Met's collection.
public struct MetMuseum: Sendable {

    let http: HTTPClient

    /// A client; `transport` replaces the network in tests.
    public init(transport: Transport? = nil) {
        http = HTTPClient(transport: transport ?? HTTPClient.live)
    }

    /// A search of the Met alone.
    public func search(_ query: ArtworkQuery) async throws -> SearchResults {
        let page = try await page(query)
        return SearchResults(artworks: page.hits.map(\.artwork), metMatches: page.total,
                             next: page.hasMore ? [.met: page.scannedTo] : [:], failures: [:])
    }

    /// One object by its number.
    public func artwork(_ number: Int) async throws -> Artwork {
        let id = ArtworkID(museum: .met, number: number)
        let object = try await http.decode(MetObjectResponse.self, from: MuseumURLs.metObject(number), museum: .met, id: id)
        return ArtworkMapping.met(object)
    }

    /// The Met's departments, for ``ArtworkQuery/metDepartment``.
    public func departments() async throws -> [Department] {
        try await http.decode(MetDepartmentsResponse.self, from: MuseumURLs.metDepartments(), museum: .met)
            .departments.map { Department(id: $0.departmentId, name: $0.displayName) }
    }

    /// The ids, then the objects read in batches until the page is full, the
    /// ids run out or ``QueryRules/metReadCap(limit:)`` is reached. Ids the
    /// search lists but the object API does not know (404) are skipped.
    func page(_ query: ArtworkQuery) async throws -> MuseumPage {
        try QueryRules.validate(query)
        let cap = QueryRules.metReadCap(limit: query.limit)
        let url = MuseumURLs.metSearch(text: query.text, imagesOnly: query.imagesOnly, years: query.years,
                                       department: query.metDepartment, limit: cap, offset: query.offset)
        let response = try await http.decode(MetSearchResponse.self, from: url, museum: .met)
        let ids = response.objectIDs ?? []
        var hits: [RankedArtwork] = []
        var read = 0
        var scannedTo = query.offset
        reading: while hits.count < query.limit, read < ids.count {
            let batch = Array(ids[read..<read + QueryRules.metBatch(needed: query.limit - hits.count, remaining: ids.count - read)])
            let objects = try await Concurrency.map(batch, width: QueryRules.metWidth) { number in
                try await objectIfKnown(number)
            }
            for (index, object) in objects.enumerated() {
                scannedTo = query.offset + read + index + 1
                guard let object else { continue }
                let artwork = ArtworkMapping.met(object)
                if query.publicDomainOnly && !artwork.isPublicDomain { continue }
                if query.imagesOnly && artwork.image == nil { continue }
                hits.append(RankedArtwork(artwork: artwork, position: scannedTo - 1))
                if hits.count == query.limit { break reading }
            }
            read += batch.count
        }
        return MuseumPage(museum: .met, hits: hits, scannedTo: scannedTo,
                          hasMore: scannedTo < response.total, total: response.total)
    }

    /// An object, or nil when the Met does not know its own search's id.
    func objectIfKnown(_ number: Int) async throws -> MetObjectResponse? {
        do {
            return try await http.decode(MetObjectResponse.self, from: MuseumURLs.metObject(number), museum: .met,
                                         id: ArtworkID(museum: .met, number: number))
        } catch MuseumError.notFound {
            return nil
        }
    }
}
