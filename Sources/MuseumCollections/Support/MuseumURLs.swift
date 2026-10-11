//
//  MuseumURLs.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  Every URL the library calls, built in one place and testable offline.
//

import Foundation

/// The two museums' endpoints.
enum MuseumURLs {

    static let metAPI = "https://collectionapi.metmuseum.org/public/collection"
    static let aicAPI = "https://api.artic.edu/api/v1"
    static let aicIIIF = "https://www.artic.edu/iiif/2"

    /// The fields asked of Chicago — everything ``Artwork`` holds and no more.
    static let aicFields = ["id", "title", "artist_title", "artist_display", "date_display", "date_start", "date_end",
                            "medium_display", "dimensions", "department_title", "classification_title",
                            "place_of_origin", "credit_line", "is_public_domain", "image_id"]

    /// The Met's search: object ids only, `limit` at most 500 (asking more
    /// returns 500). Its `isPublicDomain` parameter is accepted and ignored —
    /// measured: "sunflowers" counted 178 with and without it — so that filter
    /// is applied after the objects are read.
    static func metSearch(text: String, imagesOnly: Bool, years: ClosedRange<Int>?, department: Int?,
                          limit: Int, offset: Int) -> URL {
        var items = [URLQueryItem(name: "q", value: text), URLQueryItem(name: "limit", value: String(limit)),
                     URLQueryItem(name: "offset", value: String(offset))]
        if imagesOnly { items.append(URLQueryItem(name: "hasImages", value: "true")) }
        if let years {
            items += [URLQueryItem(name: "dateBegin", value: String(years.lowerBound)),
                      URLQueryItem(name: "dateEnd", value: String(years.upperBound))]
        }
        if let department { items.append(URLQueryItem(name: "departmentId", value: String(department))) }
        var components = URLComponents(string: metAPI + "/v1.1/search")!
        components.queryItems = items
        return components.url!
    }

    /// One Met object.
    static func metObject(_ number: Int) -> URL { URL(string: metAPI + "/v1/objects/\(number)")! }

    /// The Met's departments.
    static func metDepartments() -> URL { URL(string: metAPI + "/v1/departments")! }

    /// Chicago's search, as Elasticsearch `params`: the words, filters for
    /// public domain, an image and overlapping years, a page of `limit` (at
    /// most 100) from `offset` (`offset + limit` at most 10,000).
    static func aicSearch(text: String, publicDomainOnly: Bool, imagesOnly: Bool, years: ClosedRange<Int>?,
                          limit: Int, offset: Int) -> URL {
        var filters: [[String: Any]] = []
        if publicDomainOnly { filters.append(["term": ["is_public_domain": true]]) }
        if imagesOnly { filters.append(["exists": ["field": "image_id"]]) }
        if let years {
            filters.append(["range": ["date_end": ["gte": years.lowerBound]]])
            filters.append(["range": ["date_start": ["lte": years.upperBound]]])
        }
        var params: [String: Any] = ["q": text, "limit": limit, "from": offset, "fields": aicFields]
        if !filters.isEmpty { params["query"] = ["bool": ["filter": filters]] }
        let json = String(data: try! JSONSerialization.data(withJSONObject: params, options: [.sortedKeys]), encoding: .utf8)!
        var components = URLComponents(string: aicAPI + "/artworks/search")!
        components.queryItems = [URLQueryItem(name: "params", value: json)]
        return components.url!
    }

    /// One Chicago artwork.
    static func aicArtwork(_ number: Int) -> URL {
        var components = URLComponents(string: aicAPI + "/artworks/\(number)")!
        components.queryItems = [URLQueryItem(name: "fields", value: aicFields.joined(separator: ","))]
        return components.url!
    }

    /// A Chicago IIIF image at a width.
    static func iiif(base: URL, width: Int) -> URL {
        base.appendingPathComponent("full/\(width),/0/default.jpg")
    }

    /// A Chicago IIIF image service.
    static func iiifBase(imageID: String) -> URL? { URL(string: aicIIIF + "/" + imageID) }

    /// Chicago's page for an artwork.
    static func aicPage(_ number: Int) -> URL { URL(string: "https://www.artic.edu/artworks/\(number)")! }
}
