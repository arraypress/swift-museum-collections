//
//  ArtworkID.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An artwork's identity: its museum and that museum's object number.
///
/// Written `met:436524` or `aic:27992` (``description``); parsed from that form
/// or from a museum page URL by ``init(_:)``.
public struct ArtworkID: Hashable, Sendable, Codable {

    /// The museum holding it.
    public let museum: Museum

    /// The museum's own number for it.
    public let number: Int

    /// An identifier.
    public init(museum: Museum, number: Int) {
        self.museum = museum
        self.number = number
    }
}
