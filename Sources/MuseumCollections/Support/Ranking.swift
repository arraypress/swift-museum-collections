//
//  Ranking.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//
//  How results from two museums become one list.
//

import Foundation

/// Relevance and merging.
enum Ranking {

    /// Chicago scores every artwork for every query — "zzqqxxnothing" matched
    /// all 133,165 — so its real matches are told apart by score. Measured over
    /// six queries: real matches scored 5 to 3,995, the filler under 0.1; one is
    /// the line between them.
    static let aicMinimumScore = 1.0

    /// Whether a Chicago search hit is a real match.
    static func isRelevant(score: Double?) -> Bool {
        (score ?? 0) >= aicMinimumScore
    }

    /// The lists interleaved — first of each, then second of each — up to
    /// `limit`, so neither museum's ranking is ranked against the other's;
    /// with how many of each list were used.
    static func interleave<T>(_ lists: [[T]], limit: Int) -> (merged: [T], used: [Int]) {
        var merged: [T] = []
        var used = [Int](repeating: 0, count: lists.count)
        var index = 0
        while merged.count < limit, lists.contains(where: { index < $0.count }) {
            for (list, items) in lists.enumerated() where index < items.count && merged.count < limit {
                merged.append(items[index])
                used[list] += 1
            }
            index += 1
        }
        return (merged, used)
    }

    /// The offset that continues a museum after `used` of its hits were shown:
    /// the first unshown hit, else where its scan stopped, else nil.
    static func nextOffset(_ page: MuseumPage, used: Int) -> Int? {
        if used < page.hits.count { return page.hits[used].position }
        return page.hasMore ? page.scannedTo : nil
    }
}
