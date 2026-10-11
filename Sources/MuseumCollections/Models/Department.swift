//
//  Department.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Met curatorial department.
public struct Department: Hashable, Sendable, Codable, Identifiable {

    /// Its id, for ``ArtworkQuery/metDepartment``.
    public let id: Int

    /// Its name — "European Paintings".
    public let name: String
}
