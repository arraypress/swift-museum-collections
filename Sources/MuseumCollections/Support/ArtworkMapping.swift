//
//  ArtworkMapping.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  Each museum's record onto the common ``Artwork``.
//

import Foundation

/// Museum records → ``Artwork``.
enum ArtworkMapping {

    /// Chicago serves works that are not public domain up to 843 pixels wide
    /// (measured: 843 → 200; 1,686 → a 307 redirect), public-domain ones at any width.
    static let aicRestrictedWidth = 843

    /// Chicago's display width.
    static let aicPreviewWidth = 843

    /// A Met object. Its empty strings become nil; a work that is not public
    /// domain arrives with empty image fields, so it has no image.
    static func met(_ object: MetObjectResponse) -> Artwork {
        let id = ArtworkID(museum: .met, number: object.objectID)
        let full = nonEmpty(object.primaryImage).flatMap(URL.init(string:))
        let preview = nonEmpty(object.primaryImageSmall).flatMap(URL.init(string:)) ?? full
        return Artwork(
            id: id,
            title: nonEmpty(object.title) ?? "Untitled",
            artist: nonEmpty(object.artistDisplayName),
            artistDetails: nonEmpty(object.artistDisplayBio),
            date: nonEmpty(object.objectDate),
            years: span(object.objectBeginDate, object.objectEndDate),
            medium: nonEmpty(object.medium),
            dimensions: nonEmpty(object.dimensions),
            department: nonEmpty(object.department),
            classification: nonEmpty(object.classification),
            origin: nonEmpty(object.culture) ?? nonEmpty(object.country),
            creditLine: nonEmpty(object.creditLine),
            isPublicDomain: object.isPublicDomain ?? false,
            image: full.flatMap { full in
                preview.map { ArtworkImage(preview: $0, full: full, iiifBase: nil, maximumWidth: nil) }
            },
            url: nonEmpty(object.objectURL).flatMap(URL.init(string:))
                ?? URL(string: "https://www.metmuseum.org/art/collection/search/\(object.objectID)")!
        )
    }

    /// A Chicago artwork.
    static func aic(_ record: AICArtworkResponse) -> Artwork {
        let publicDomain = record.is_public_domain ?? false
        let (artist, details) = artist(display: record.artist_display, title: record.artist_title)
        let base = nonEmpty(record.image_id).flatMap(MuseumURLs.iiifBase(imageID:))
        let maximum = publicDomain ? nil : aicRestrictedWidth
        return Artwork(
            id: ArtworkID(museum: .aic, number: record.id),
            title: nonEmpty(record.title) ?? "Untitled",
            artist: artist,
            artistDetails: details,
            date: nonEmpty(record.date_display),
            years: span(record.date_start, record.date_end),
            medium: nonEmpty(record.medium_display),
            dimensions: nonEmpty(record.dimensions),
            department: nonEmpty(record.department_title),
            classification: nonEmpty(record.classification_title),
            origin: nonEmpty(record.place_of_origin),
            creditLine: nonEmpty(record.credit_line),
            isPublicDomain: publicDomain,
            image: base.map { base in
                ArtworkImage(preview: MuseumURLs.iiif(base: base, width: aicPreviewWidth),
                             full: MuseumURLs.iiif(base: base, width: maximum ?? 3_000),
                             iiifBase: base, maximumWidth: maximum)
            },
            url: MuseumURLs.aicPage(record.id)
        )
    }

    /// Chicago's artist: the name, and its nationality and dates. Its
    /// `artist_display` comes in two shapes, both measured —
    /// "Katsushika Hokusai 葛飾 北斎\nJapanese, 1760-1849" and
    /// "Georges Seurat (French, 1859–1891)" — and `artist_title` holds the
    /// bare name when there is one.
    static func artist(display: String?, title: String?) -> (name: String?, details: String?) {
        let lines = (display ?? "").split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let name = nonEmpty(title)
        guard let first = lines.first else { return (name, nil) }
        if lines.count > 1 { return (name ?? first, nonEmpty(lines.dropFirst().joined(separator: ", "))) }
        if first.hasSuffix(")"), let open = first.range(of: " (", options: .backwards) {
            let inner = first[open.upperBound..<first.index(before: first.endIndex)]
            return (name ?? nonEmpty(String(first[..<open.lowerBound])), nonEmpty(String(inner)))
        }
        return (name ?? first, nil)
    }

    /// Text, or nil when empty or only spaces.
    static func nonEmpty(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// A span of years from a begin and end, either missing; reversed ends are
    /// put in order. Both museums write BCE as negative years.
    static func span(_ start: Int?, _ end: Int?) -> ClosedRange<Int>? {
        switch (start, end) {
        case let (a?, b?): return min(a, b)...max(a, b)
        case let (a?, nil): return a...a
        case let (nil, b?): return b...b
        default: return nil
        }
    }
}
