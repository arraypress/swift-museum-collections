//
//  MetSearchResponse.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The Met's `v1.1/search` body. `objectIDs` is null, not empty, when nothing matches.
struct MetSearchResponse: Decodable {
    let total: Int
    let objectIDs: [Int]?
}
