//
//  AICArtworkResponse.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One Art Institute artwork, with its search score when it came from a search.
struct AICArtworkResponse: Decodable {
    let _score: Double?
    let id: Int
    let title: String?
    let artist_title: String?
    let artist_display: String?
    let date_display: String?
    let date_start: Int?
    let date_end: Int?
    let medium_display: String?
    let dimensions: String?
    let department_title: String?
    let classification_title: String?
    let place_of_origin: String?
    let credit_line: String?
    let is_public_domain: Bool?
    let image_id: String?
}
