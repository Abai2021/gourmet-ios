import Foundation

// 食物类别模型
struct FoodCategory: Codable {
    let id: Int
    let name: String
}

// 食物模型
struct Food: Codable, Identifiable {
    let id: Int
    let name: String
    let evaluation: String
    let imageUrl: String
    let standardCalories: Int
    let category: [FoodCategory]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case evaluation
        case imageUrl = "image_url"
        case standardCalories = "standard_calories"
        case category
    }
}

// 食物搜索响应
struct FoodSearchResponse: Codable {
    let success: Bool
    let data: FoodSearchData
    let requestId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case requestId = "request_id"
    }
}

// 食物搜索数据
struct FoodSearchData: Codable {
    let keyword: String
    let limit: Int
    let list: [Food]
    let page: Int
    let total: Int
}

// 创建饮食记录请求
struct CreateDietRecordRequest: Codable {
    let date: String
    let mealType: Int
    let foods: [CreateFoodItem]
    
    enum CodingKeys: String, CodingKey {
        case date
        case mealType = "meal_type"
        case foods
    }
}

// 创建食物项
struct CreateFoodItem: Codable {
    let foodId: Int
    let amount: Double
    let unit: String
    let calories: Int
    let protein: Double?
    let fat: Double?
    let carbohydrate: Double?
    
    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case amount
        case unit
        case calories
        case protein
        case fat
        case carbohydrate
    }
}
