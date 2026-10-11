//
//  ArtInstitute.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  The Art Institute of Chicago's API: keyless, about 133,000 artworks,
//  images through IIIF.
//

import Foundation

/// The Art Institute of Chicago's collection.
public struct ArtInstitute: Sendable {

    let http: HTTPClient

    /// A client; `transport` replaces the network in tests.
    public init(transport: Transport? = nil) {
        http = HTTPClient(transport: transport ?? HTTPClient.live)
    }

    /// A search of Chicago alone.
    public func search(_ query: ArtworkQuery) async throws(MuseumError) -> SearchResults {
        let page = try await page(query)
        return SearchResults(artworks: page.hits.map(\.artwork), metMatches: nil,
                             next: page.hasMore ? [.aic: page.scannedTo] : [:], failures: [:])
    }

    /// One artwork by its number.
    public func artwork(_ number: Int) async throws(MuseumError) -> Artwork {
        let id = ArtworkID(museum: .aic, number: number)
        let envelope = try await http.decode(AICArtworkEnvelope.self, from: MuseumURLs.aicArtwork(number), museum: .aic, id: id)
        return ArtworkMapping.aic(envelope.data)
    }

    /// One page, filtered by Chicago, cut at the relevance line
    /// (``Ranking/aicMinimumScore``).
    func page(_ query: ArtworkQuery) async throws(MuseumError) -> MuseumPage {
        try QueryRules.validate(query)
        try QueryRules.validateChicago(query)
        let url = MuseumURLs.aicSearch(text: query.text, publicDomainOnly: query.publicDomainOnly,
                                       imagesOnly: query.imagesOnly, years: query.years,
                                       limit: query.limit, offset: query.offset)
        let response = try await http.decode(AICSearchResponse.self, from: url, museum: .aic)
        let relevant = response.data.prefix { Ranking.isRelevant(score: $0._score) }
        let hits = relevant.enumerated().map { index, record in
            RankedArtwork(artwork: ArtworkMapping.aic(record), position: query.offset + index)
        }
        let scannedTo = query.offset + hits.count
        let full = relevant.count == response.data.count && response.data.count == query.limit
        return MuseumPage(museum: .aic, hits: hits, scannedTo: scannedTo,
                          hasMore: full && scannedTo < QueryRules.aicDepthLimit, total: nil)
    }
}
