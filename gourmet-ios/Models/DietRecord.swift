//
//  DietRecord.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/6.
//

import Foundation

// MARK: - 饮食记录返回数据模型
struct DietRecordResponse: Codable {
    let success: Bool
    let data: [DietRecord]?
    let requestId: String
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case requestId = "request_id"
        case message
    }
}

// MARK: - 饮食记录
struct DietRecord: Codable {
    let id: Int
    let date: String
    let mealType: Int
    let foods: [FoodItem]
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case mealType = "meal_type"
        case foods
    }
    
    // 获取餐类型的名称
    var mealTypeName: String {
        switch mealType {
        case 1:
            return "早餐"
        case 2:
            return "午餐"
        case 3:
            return "晚餐"
        case 4:
            return "零食"
        default:
            return "其他"
        }
    }
}

// MARK: - 食物项
struct FoodItem: Codable {
    let id: Int
    let foodId: Int
    let name: String
    let image: String
    let amount: Int
    let unit: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbohydrate: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case foodId = "food_id"
        case name
        case image
        case amount
        case unit
        case calories
        case protein
        case fat
        case carbohydrate
    }
}

// MARK: - 营养摄入汇总
struct NutritionSummary {
    var totalCalories: Int = 0
    var totalProtein: Double = 0
    var totalFat: Double = 0
    var totalCarbohydrate: Double = 0
    
    mutating func add(foodItem: FoodItem) {
        totalCalories += foodItem.calories
        totalProtein += foodItem.protein
        totalFat += foodItem.fat
        totalCarbohydrate += foodItem.carbohydrate
    }
}
