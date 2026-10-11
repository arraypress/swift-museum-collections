//
//  ArtworkQuery.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What to search for.
public struct ArtworkQuery: Hashable, Sendable {

    /// The words to search for.
    public var text: String

    /// Which museums to ask; both by default.
    public var museums: [Museum]

    /// Only works the museum marks public domain.
    public var publicDomainOnly: Bool

    /// Only works with an image (the default).
    public var imagesOnly: Bool

    /// Only works whose dates overlap these years; negative years are BCE.
    public var years: ClosedRange<Int>?

    /// The Met only: a department's id (see ``MetMuseum/departments()``).
    public var metDepartment: Int?

    /// At most this many results, 1–100 (default 10).
    public var limit: Int

    /// Results to skip, per museum — for the next page.
    public var offset: Int

    /// A query.
    public init(_ text: String, museums: [Museum] = Museum.allCases, publicDomainOnly: Bool = false,
                imagesOnly: Bool = true, years: ClosedRange<Int>? = nil, metDepartment: Int? = nil,
                limit: Int = 10, offset: Int = 0) {
        self.text = text
        self.museums = museums
        self.publicDomainOnly = publicDomainOnly
        self.imagesOnly = imagesOnly
        self.years = years
        self.metDepartment = metDepartment
        self.limit = limit
        self.offset = offset
    }
}
