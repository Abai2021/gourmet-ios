//
//  FoodCategory.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/1.
//

import Foundation

struct FoodCategoryResponse: Codable {
    let success: Bool
    let data: [FoodCategory]
    let request_id: String
}

struct FoodCategory: Codable {
    let id: Int
    let name: String
}
