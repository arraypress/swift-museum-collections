//
//  MuseumError.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why a museum request failed.
public enum MuseumError: Error, LocalizedError, Sendable, Equatable {

    /// The query cannot be sent: empty text, a limit or offset out of range.
    case invalidQuery(String)

    /// Text that is not an artwork identifier (`met:436524`, `aic:27992`).
    case badIdentifier(String)

    /// The museum has no artwork with this identifier.
    case notFound(ArtworkID)

    /// The artwork has no image the museum shares.
    case noImage(ArtworkID)

    /// The artwork is not in the public domain, and the caller did not
    /// insist on downloading it.
    case notPublicDomain(ArtworkID)

    /// The museum is rate-limiting.
    case rateLimited(Museum)

    /// The museum answered with an unexpected HTTP status.
    case http(Museum, Int)

    /// The museum answered in a shape this library does not understand.
    case malformed(Museum, String)

    /// The request did not reach the museum.
    case network(String)

    /// The downloaded image could not be written.
    case file(String)

    /// The task was cancelled before the museums answered.
    case cancelled

    /// A sentence describing the failure.
    public var errorDescription: String? {
        switch self {
        case .invalidQuery(let why): return why
        case .badIdentifier(let text): return "'\(text)' is not an artwork id — use met:436524 or aic:27992"
        case .notFound(let id): return "No artwork \(id)"
        case .noImage(let id): return "\(id) has no image the museum shares"
        case .notPublicDomain(let id):
            return "\(id) is not in the public domain; its image is shared for viewing, not for reuse"
        case .rateLimited(let museum): return "\(museum.name) is rate-limiting"
        case .http(let museum, let code): return "\(museum.name) answered HTTP \(code)"
        case .malformed(let museum, let what): return "Unexpected response from \(museum.name): \(what)"
        case .network(let why): return "Network error: \(why)"
        case .file(let why): return "Cannot write the image: \(why)"
        case .cancelled: return "Cancelled"
        }
    }
}
