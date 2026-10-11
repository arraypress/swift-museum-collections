//
//  ImageSizing.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Picking a rendition.
enum ImageSizing {

    /// A rendition at about `width` pixels: an exact one from a IIIF service,
    /// capped at the museum's maximum; otherwise the preview for widths up to
    /// 1,000 and the full image above.
    static func url(for image: ArtworkImage, width: Int?) -> URL {
        guard let width else { return image.full }
        if let base = image.iiifBase {
            return MuseumURLs.iiif(base: base, width: min(max(1, width), image.maximumWidth ?? width))
        }
        return width <= 1_000 ? image.preview : image.full
    }
}
