import Foundation

// 食物详情模型
struct FoodDetail: Codable {
    let id: Int
    let name: String
    let evaluation: String?
    let image_url: String?
    let standard_calories: Int
    let category: [FoodCategory]?
    let material_infos: MaterialInfos?
    let nutrition: [NutritionInfo]?
    let productions: [ProductionStep]?
    let relations: [RelatedFood]?
    let food_unit_infos: [FoodUnitInfo]?
}

// 食物详情响应
struct FoodDetailResponse: Codable {
    let success: Bool
    let data: FoodDetail
    let request_id: String
}

// 营养信息
struct NutritionInfo: Codable {
    let name: String
    let amount: String
    let unit: String
}

// 食物单位信息
struct FoodUnitInfo: Codable {
    let food_id: Int
    let amount: Double
    let unit: String
    let total_weight: Double
    let edible_weight: Double
    let calories: Double
    let calories_unit: String
    let is_standard: Bool
}

// 菜谱材料信息
struct MaterialInfos: Codable {
    let major: [MaterialItem]?
    let seasoning: [MaterialItem]?
}

// 材料项
struct MaterialItem: Codable {
    let name: String
    let amount: String
    let unit: String
}

// 制作步骤
struct ProductionStep: Codable {
    let food_id: Int
    let step: Int
    let content: String
}

// 相关食物
struct RelatedFood: Codable {
    let id: Int
    let name: String
    let evaluation: String?
    let image_url: String?
    let standard_calories: Int
    let category: [FoodCategory]?
}
