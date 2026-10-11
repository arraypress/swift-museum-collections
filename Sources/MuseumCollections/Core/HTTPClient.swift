//
//  HTTPClient.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  The one place requests are sent: headers on, statuses mapped onto ``MuseumError``.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// GETs against the museums.
struct HTTPClient: Sendable {

    /// The transport in use.
    let transport: Transport

    /// `URLSession.shared`, 20 seconds a request.
    static let live: Transport = { request in
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }

    /// A GET. `id` turns a 404 into ``MuseumError/notFound(_:)``.
    func fetch(_ url: URL, from museum: Museum, id: ArtworkID? = nil) async throws -> (Data, HTTPURLResponse) {
        let response: (Data, HTTPURLResponse)
        do {
            response = try await transport(RequestHeaders.request(for: url))
        } catch let error as MuseumError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw MuseumError.network(error.localizedDescription)
        }
        if let error = HTTPStatus.error(for: response.1.statusCode, museum: museum, id: id) { throw error }
        return response
    }

    /// A GET decoded as JSON.
    func decode<T: Decodable>(_ type: T.Type, from url: URL, museum: Museum, id: ArtworkID? = nil) async throws -> T {
        let (data, _) = try await fetch(url, from: museum, id: id)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw MuseumError.malformed(museum, HTTPStatus.describe(error))
        }
    }
}
