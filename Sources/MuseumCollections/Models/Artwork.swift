//
//  Artwork.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One artwork, in the same shape whichever museum holds it.
public struct Artwork: Hashable, Sendable, Codable, Identifiable {

    /// Museum and object number.
    public let id: ArtworkID

    /// The title.
    public let title: String

    /// The artist's name, when known.
    public let artist: String?

    /// Nationality, places and dates of the artist, as the museum writes them.
    public let artistDetails: String?

    /// The date as the museum writes it — "1887", "ca. 500–480 B.C.", "c. 1950".
    public let date: String?

    /// The span of years the date covers; negative years are BCE.
    public let years: ClosedRange<Int>?

    /// What it is made of — "Oil on canvas".
    public let medium: String?

    /// Its size, as the museum writes it.
    public let dimensions: String?

    /// The museum department holding it.
    public let department: String?

    /// Its kind — "Paintings", "Ceramics".
    public let classification: String?

    /// The culture or place it comes from.
    public let origin: String?

    /// How the museum acquired it — the line to credit.
    public let creditLine: String?

    /// Whether the museum marks it public domain — free to reuse.
    public let isPublicDomain: Bool

    /// The image the museum shares; `nil` when it shares none (the Met shares
    /// none for works that are not public domain).
    public let image: ArtworkImage?

    /// The artwork's page on the museum's website.
    public let url: URL
}
