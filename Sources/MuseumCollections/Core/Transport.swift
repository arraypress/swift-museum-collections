//
//  Transport.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// How a request reaches the network — `URLSession` unless a test swaps it.
public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
