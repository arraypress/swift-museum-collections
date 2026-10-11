//
//  QueryRules.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What a query may ask, and how much reading a Met search may do.
enum QueryRules {

    /// Chicago pages no further than this many results.
    static let aicDepthLimit = 10_000

    /// Objects read at once while hydrating a Met search.
    static let metWidth = 8

    /// A query's text and numbers, checked before anything is sent.
    static func validate(_ query: ArtworkQuery) throws {
        guard !query.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MuseumError.invalidQuery("The search text is empty")
        }
        guard (1...100).contains(query.limit) else { throw MuseumError.invalidQuery("The limit must be 1–100") }
        guard query.offset >= 0 else { throw MuseumError.invalidQuery("The offset cannot be negative") }
        if let years = query.years, years.upperBound - years.lowerBound > 20_000 {
            throw MuseumError.invalidQuery("The year range is wider than 20,000 years")
        }
    }

    /// Chicago's depth: `offset + limit` within 10,000.
    static func validateChicago(_ query: ArtworkQuery) throws {
        guard query.offset + query.limit <= aicDepthLimit else {
            throw MuseumError.invalidQuery("The Art Institute pages no further than result 10,000")
        }
    }

    /// The most Met objects one search reads. The Met's search returns ids
    /// only, and each object is a second request; works without an image or
    /// outside the public domain are read and dropped, so a page of `limit`
    /// can need several times as many reads. Capped so a filtered search
    /// cannot run away.
    static func metReadCap(limit: Int) -> Int {
        min(200, limit * 4 + 10)
    }

    /// How many Met objects to read next, still needing `needed`.
    static func metBatch(needed: Int, remaining: Int) -> Int {
        min(remaining, max(metWidth, needed * 2))
    }
}
