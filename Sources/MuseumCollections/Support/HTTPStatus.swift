//
//  HTTPStatus.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Statuses and decode failures as ``MuseumError``.
enum HTTPStatus {

    /// The error for a status, or nil for success. A 404 is ``MuseumError/notFound(_:)``
    /// only when an artwork was asked for.
    static func error(for status: Int, museum: Museum, id: ArtworkID?) -> MuseumError? {
        switch status {
        case 200..<300: return nil
        case 404 where id != nil: return .notFound(id!)
        case 429: return .rateLimited(museum)
        default: return .http(museum, status)
        }
    }

    /// A decoding failure in a sentence, naming the field.
    static func describe(_ error: Error) -> String {
        guard let error = error as? DecodingError else { return error.localizedDescription }
        switch error {
        case .keyNotFound(let key, _): return "missing '\(key.stringValue)'"
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            return "unexpected '\(context.codingPath.map(\.stringValue).joined(separator: "."))'"
        case .dataCorrupted: return "not JSON"
        @unknown default: return "undecodable"
        }
    }
}
