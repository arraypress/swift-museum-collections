//
//  ArtworkImage.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The image a museum shares for an artwork.
///
/// ``url(width:)`` (in `Extensions/ArtworkImage+Sizing.swift`) gives a
/// rendition at a width, within what the museum allows.
public struct ArtworkImage: Hashable, Sendable, Codable {

    /// A rendition around 800–1,000 pixels wide, good for display.
    public let preview: URL

    /// The largest rendition the museum allows for this artwork.
    public let full: URL

    /// The IIIF image service, when the museum runs one (Chicago): any width
    /// can be asked of it, up to ``maximumWidth``.
    public let iiifBase: URL?

    /// The widest rendition allowed, in pixels; `nil` when the original is
    /// shared. Chicago caps works that are not public domain at 843.
    public let maximumWidth: Int?

    /// An image.
    public init(preview: URL, full: URL, iiifBase: URL?, maximumWidth: Int?) {
        self.preview = preview
        self.full = full
        self.iiifBase = iiifBase
        self.maximumWidth = maximumWidth
    }
}
