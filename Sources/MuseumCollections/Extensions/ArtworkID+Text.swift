//
//  ArtworkID+Text.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

extension ArtworkID: CustomStringConvertible {

    /// `met:436524`.
    public var description: String { Identifiers.text(self) }

    /// An id from `met:436524`, `aic:27992` or a museum page URL; nil otherwise.
    public init?(_ text: String) {
        guard let parsed = Identifiers.parse(text) else { return nil }
        self = parsed
    }
}
