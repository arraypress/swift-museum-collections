//
//  ImageFiles.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Where a downloaded image goes.
enum ImageFiles {

    /// The extension for an image content type.
    static func fileExtension(for contentType: String) -> String {
        let type = contentType.split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? ""
        switch type {
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "image/webp": return "webp"
        case "image/tiff": return "tif"
        default: return "jpg"
        }
    }

    /// The file to write: `destination` itself, or — when it is a folder —
    /// `met-436524.jpg` inside it.
    static func file(at destination: URL, isDirectory: Bool, id: ArtworkID, contentType: String) -> URL {
        guard isDirectory else { return destination }
        return destination.appendingPathComponent("\(id.museum.rawValue)-\(id.number).\(fileExtension(for: contentType))")
    }
}
