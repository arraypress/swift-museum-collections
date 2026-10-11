//
//  Museum.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A collection this library reads.
public enum Museum: String, CaseIterable, Sendable, Codable {

    /// The Metropolitan Museum of Art, New York.
    case met

    /// The Art Institute of Chicago.
    case aic

    /// The museum's name.
    public var name: String {
        switch self {
        case .met: return "The Metropolitan Museum of Art"
        case .aic: return "The Art Institute of Chicago"
        }
    }
}
