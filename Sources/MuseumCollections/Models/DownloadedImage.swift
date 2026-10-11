//
//  DownloadedImage.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An image written to disk.
public struct DownloadedImage: Hashable, Sendable {

    /// The artwork it shows.
    public let artwork: ArtworkID

    /// Where it was written.
    public let file: URL

    /// Its size in bytes.
    public let bytes: Int

    /// The URL it came from.
    public let source: URL

    /// Whether the artwork is public domain.
    public let isPublicDomain: Bool
}
