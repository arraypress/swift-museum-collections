//
//  MuseumPage.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One museum's share of a search, before merging.
struct MuseumPage: Sendable {

    /// The museum.
    let museum: Museum

    /// The kept artworks, in the museum's order.
    let hits: [RankedArtwork]

    /// The position after the last match looked at.
    let scannedTo: Int

    /// Whether matches remain past ``scannedTo``.
    let hasMore: Bool

    /// The museum's own match count, when it means something (the Met's does;
    /// Chicago's counts the whole collection).
    let total: Int?
}
