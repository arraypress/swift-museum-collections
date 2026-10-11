//
//  MetDepartmentResponse.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One Met department.
struct MetDepartmentResponse: Decodable {
    let departmentId: Int
    let displayName: String
}
