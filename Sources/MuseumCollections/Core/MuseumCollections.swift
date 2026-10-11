//
//  MuseumCollections.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  The public surface: one search over both museums, lookup by id, and
//  image downloads that respect each work's rights.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The Met and the Art Institute of Chicago as one collection.
///
/// ```swift
/// let museums = MuseumCollections()
/// let results = try await museums.search(ArtworkQuery("sunflowers", publicDomainOnly: true))
/// let work = try await museums.artwork(ArtworkID("met:436524")!)
/// let saved = try await museums.download(work.id, to: URL(fileURLWithPath: "."), width: 1200)
/// ```
///
/// Both APIs are open: no key, no account.
public struct MuseumCollections: Sendable {

    /// The Met on its own.
    public let met: MetMuseum

    /// The Art Institute of Chicago on its own.
    public let artInstitute: ArtInstitute

    let http: HTTPClient

    /// A client; `transport` replaces the network in tests.
    public init(transport: Transport? = nil) {
        let transport = transport ?? HTTPClient.live
        met = MetMuseum(transport: transport)
        artInstitute = ArtInstitute(transport: transport)
        http = HTTPClient(transport: transport)
    }

    /// A search of the query's museums at once, interleaved. A museum that
    /// fails is reported in ``SearchResults/failures`` while the other's
    /// results still come back; when every museum fails, the first error is
    /// thrown. A ``ArtworkQuery/metDepartment`` asks the Met alone.
    public func search(_ query: ArtworkQuery) async throws -> SearchResults {
        try QueryRules.validate(query)
        let museums = Museum.allCases.filter {
            query.museums.contains($0) && (query.metDepartment == nil || $0 == .met)
        }
        guard !museums.isEmpty else { throw MuseumError.invalidQuery("No museum to search") }

        async let metOutcome = museums.contains(.met) ? attempt { try await met.page(query) } : nil
        async let aicOutcome = museums.contains(.aic) ? attempt { try await artInstitute.page(query) } : nil
        let outcomes: [(Museum, Result<MuseumPage, Error>?)] = [(.met, await metOutcome), (.aic, await aicOutcome)]

        var pages: [MuseumPage] = []
        var failures: [Museum: String] = [:]
        var firstError: Error?
        for case let (museum, outcome?) in outcomes {
            switch outcome {
            case .success(let page): pages.append(page)
            case .failure(let error):
                if error is CancellationError { throw error }
                firstError = firstError ?? error
                failures[museum] = error.localizedDescription
            }
        }
        if pages.isEmpty, let firstError { throw firstError }

        let (merged, used) = Ranking.interleave(pages.map { $0.hits.map(\.artwork) }, limit: query.limit)
        var next: [Museum: Int] = [:]
        for (page, count) in zip(pages, used) {
            next[page.museum] = Ranking.nextOffset(page, used: count)
        }
        return SearchResults(artworks: merged, metMatches: pages.first { $0.museum == .met }?.total,
                             next: next, failures: failures)
    }

    /// One artwork by its id.
    public func artwork(_ id: ArtworkID) async throws -> Artwork {
        switch id.museum {
        case .met: return try await met.artwork(id.number)
        case .aic: return try await artInstitute.artwork(id.number)
        }
    }

    /// An artwork's image saved to `destination` — a file, or a folder to put
    /// `met-436524.jpg` in.
    ///
    /// Works outside the public domain throw ``MuseumError/notPublicDomain(_:)``
    /// unless `allowRestricted`: the museums share those images for viewing,
    /// not reuse. `width` picks a size where the museum offers one (Chicago's
    /// IIIF, at most 843 pixels for restricted works); `nil` is the largest.
    public func download(_ id: ArtworkID, to destination: URL, width: Int? = nil,
                         allowRestricted: Bool = false) async throws -> DownloadedImage {
        if let width, width < 1 { throw MuseumError.invalidQuery("The width must be at least 1") }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDirectory)
        let intoFolder = exists && isDirectory.boolValue
        let parent = destination.deletingLastPathComponent()
        if !intoFolder && !FileManager.default.fileExists(atPath: parent.path) {
            throw MuseumError.file("there is no folder \(parent.path)")
        }
        let work = try await artwork(id)
        guard let image = work.image else { throw MuseumError.noImage(id) }
        guard work.isPublicDomain || allowRestricted else { throw MuseumError.notPublicDomain(id) }

        let source = image.url(width: width)
        let data: Data, response: HTTPURLResponse
        do {
            (data, response) = try await http.fetch(source, from: id.museum)
        } catch MuseumError.http(_, 404) {
            throw MuseumError.noImage(id)
        }
        let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard contentType.lowercased().hasPrefix("image/") else {
            throw MuseumError.malformed(id.museum, "expected an image, got \(contentType.isEmpty ? "no content type" : contentType)")
        }

        let file = ImageFiles.file(at: destination, isDirectory: intoFolder, id: id, contentType: contentType)
        do {
            try data.write(to: file, options: .atomic)
        } catch {
            throw MuseumError.file(error.localizedDescription)
        }
        return DownloadedImage(artwork: id, file: file, bytes: data.count, source: source, isPublicDomain: work.isPublicDomain)
    }

    /// A museum's page, its failure kept rather than thrown.
    func attempt(_ body: () async throws -> MuseumPage) async -> Result<MuseumPage, Error> {
        do {
            return .success(try await body())
        } catch {
            return .failure(error)
        }
    }
}
