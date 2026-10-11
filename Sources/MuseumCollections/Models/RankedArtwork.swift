//
//  RankedArtwork.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An artwork and where it stood in its museum's own result list.
struct RankedArtwork: Sendable {

    /// The artwork.
    let artwork: Artwork

    /// Its position among the museum's raw matches, counting from offset 0.
    let position: Int
}
