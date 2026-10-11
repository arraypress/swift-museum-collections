//
//  ErrorMapping.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Any error as a ``MuseumError`` — the public API throws nothing else.
enum ErrorMapping {

    /// The library's own error unchanged; cancellation, however it arrives,
    /// as ``MuseumError/cancelled``; anything else as a network failure.
    static func museumError(_ error: any Error) -> MuseumError {
        if let error = error as? MuseumError { return error }
        if error is CancellationError { return .cancelled }
        if let error = error as? URLError, error.code == .cancelled { return .cancelled }
        return .network(error.localizedDescription)
    }
}
