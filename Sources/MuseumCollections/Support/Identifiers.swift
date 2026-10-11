//
//  Identifiers.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  Artwork ids as text, both ways.
//

import Foundation

/// Reading and writing ``ArtworkID``.
enum Identifiers {

    /// `met:436524`, `aic:27992`, or a museum page URL
    /// (`metmuseum.org/art/collection/search/436524`, `artic.edu/artworks/27992/…`).
    /// A bare number is refused: it names no museum.
    static func parse(_ text: String) -> ArtworkID? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
        if parts.count == 2, let museum = Museum(rawValue: parts[0].lowercased()),
           let number = Int(parts[1]), number > 0 {
            return ArtworkID(museum: museum, number: number)
        }
        guard let url = URL(string: trimmed), let host = url.host?.lowercased() else { return nil }
        let path = url.pathComponents
        if host.hasSuffix("metmuseum.org"), let i = path.firstIndex(of: "search"), i + 1 < path.count,
           let number = Int(path[i + 1]), number > 0 {
            return ArtworkID(museum: .met, number: number)
        }
        if host.hasSuffix("artic.edu"), let i = path.firstIndex(of: "artworks"), i + 1 < path.count,
           let number = Int(path[i + 1]), number > 0 {
            return ArtworkID(museum: .aic, number: number)
        }
        return nil
    }

    /// `met:436524`.
    static func text(_ id: ArtworkID) -> String {
        "\(id.museum.rawValue):\(id.number)"
    }
}
