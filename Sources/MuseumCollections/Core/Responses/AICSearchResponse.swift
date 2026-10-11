//
//  AICSearchResponse.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The Art Institute's search body. Its `total` counts the whole collection
/// for any query — even nonsense — so it is not read.
struct AICSearchResponse: Decodable {
    let data: [AICArtworkResponse]
}
