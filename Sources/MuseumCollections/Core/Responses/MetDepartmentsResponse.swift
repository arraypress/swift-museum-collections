//
//  MetDepartmentsResponse.swift
//  MuseumCollections
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The Met's departments list.
struct MetDepartmentsResponse: Decodable {
    let departments: [MetDepartmentResponse]
}
