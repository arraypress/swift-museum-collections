//
//  ArtworkImage+Sizing.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

public extension ArtworkImage {

    /// A rendition at about this width, within what the museum allows; the
    /// largest allowed for `nil`.
    func url(width: Int?) -> URL { ImageSizing.url(for: self, width: width) }
}
