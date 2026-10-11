//
//  RequestHeaders.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// What every request carries.
enum RequestHeaders {

    /// Who is asking, with a way to reach the author — both museums ask for it.
    static let userAgent = "MuseumCollections/0.1 (https://github.com/arraypress/swift-museum-collections)"

    /// A GET for `url`. Chicago asks for its own `AIC-User-Agent` header, and
    /// its image server refuses without it: measured 403 with only
    /// `User-Agent`, 200 with both. So every `artic.edu` host gets it.
    static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if isChicago(url) { request.setValue(userAgent, forHTTPHeaderField: "AIC-User-Agent") }
        return request
    }

    /// Whether the URL is one of Chicago's hosts.
    static func isChicago(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "artic.edu" || host.hasSuffix(".artic.edu")
    }
}
