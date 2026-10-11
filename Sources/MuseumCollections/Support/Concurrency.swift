//
//  Concurrency.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Bounded parallel work.
enum Concurrency {

    /// `transform` over `items` in a task group with at most `width` children
    /// in flight, results in the items' order. The first error cancels the
    /// children still running and is rethrown; a cancelled caller stops
    /// adding work.
    static func map<T: Sendable, R: Sendable>(_ items: [T], width: Int,
                                              _ transform: @escaping @Sendable (T) async throws -> R) async throws -> [R] {
        try await withThrowingTaskGroup(of: (Int, R).self) { group in
            var results = [R?](repeating: nil, count: items.count)
            var next = 0
            func add() throws {
                try Task.checkCancellation()
                let index = next
                group.addTask { (index, try await transform(items[index])) }
                next += 1
            }
            while next < min(max(1, width), items.count) { try add() }
            while let (index, result) = try await group.next() {
                results[index] = result
                if next < items.count { try add() }
            }
            return results.compactMap { $0 }
        }
    }
}
