//
//  SearchResults.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One page of a search across museums.
public struct SearchResults: Sendable {

    /// The artworks, best first — the museums' rankings interleaved.
    public let artworks: [Artwork]

    /// How many works the Met reports matching, before any public-domain
    /// filter (which it does not apply itself); `nil` when it was not asked.
    public let metMatches: Int?

    /// For each museum with more to give, the ``ArtworkQuery/offset`` that
    /// continues it. Offsets count the museum's own matches, filtered or not,
    /// so the two museums' next offsets usually differ.
    public let next: [Museum: Int]

    /// Museums that were asked and failed, with why; the others' results are
    /// still returned.
    public let failures: [Museum: String]

    /// Results, as a search returns them.
    public init(artworks: [Artwork], metMatches: Int?, next: [Museum: Int], failures: [Museum: String]) {
        self.artworks = artworks
        self.metMatches = metMatches
        self.next = next
        self.failures = failures
    }
}
