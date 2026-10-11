//
//  MetObjectResponse.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Met object. Text fields arrive as empty strings rather than null when
/// unknown — the image fields too, for every work that is not public domain.
struct MetObjectResponse: Decodable {
    let objectID: Int
    let title: String?
    let artistDisplayName: String?
    let artistDisplayBio: String?
    let objectDate: String?
    let objectBeginDate: Int?
    let objectEndDate: Int?
    let medium: String?
    let dimensions: String?
    let department: String?
    let classification: String?
    let culture: String?
    let country: String?
    let creditLine: String?
    let isPublicDomain: Bool?
    let primaryImage: String?
    let primaryImageSmall: String?
    let objectURL: String?
}
