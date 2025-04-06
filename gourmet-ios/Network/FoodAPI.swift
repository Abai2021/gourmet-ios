import Foundation
import Alamofire

class FoodAPI {
    static let shared = FoodAPI()
    private let baseURL = "https://gourmet.pfcent.com/api/v1"
    
    private init() {}
    
    // 搜索食物
    func searchFoods(keyword: String, page: Int = 1, limit: Int = 20, completion: @escaping (Result<[Food], Error>) -> Void) {
        guard User.isTokenValid() else {
            completion(.failure(NSError(domain: "FoodAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])))
            return
        }
        
        // 创建URL并进行编码
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/foods/search?keyword=\(encodedKeyword)&page=\(page)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "FoodAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 添加请求头
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 打印请求详情
        print("搜索食物请求: \(urlString)")
        
        // 发送请求
        AF.request(request).responseDecodable(of: FoodSearchResponse.self) { response in
            print("食物搜索响应状态码: \(response.response?.statusCode ?? 0)")
            
            // 打印响应数据
            if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                print("食物搜索响应数据: \(responseString)")
            }
            
            switch response.result {
            case .success(let foodSearchResponse):
                if foodSearchResponse.success {
                    completion(.success(foodSearchResponse.data.list))
                } else {
                    completion(.failure(NSError(domain: "FoodAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "请求失败"])))
                }
                
            case .failure(let error):
                print("食物搜索请求失败: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // 创建饮食记录
    func createDietRecord(date: String, mealType: Int, foods: [CreateFoodItem], completion: @escaping (Result<[DietRecord], Error>) -> Void) {
        guard User.isTokenValid() else {
            completion(.failure(NSError(domain: "FoodAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])))
            return
        }
        
        // 创建URL
        let urlString = "\(baseURL)/directs"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "FoodAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        // 准备请求数据
        let recordRequest = CreateDietRecordRequest(date: date, mealType: mealType, foods: foods)
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加请求头
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 尝试编码请求体
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(recordRequest)
            
            // 打印请求详情
            print("创建饮食记录请求: \(urlString)")
            if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
                print("请求内容: \(requestBody)")
            }
            
            // 发送请求
            AF.request(request).responseDecodable(of: DietRecordResponse.self) { response in
                print("创建饮食记录响应状态码: \(response.response?.statusCode ?? 0)")
                
                // 打印响应数据
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print("创建饮食记录响应数据: \(responseString)")
                }
                
                switch response.result {
                case .success(let dietRecordResponse):
                    if dietRecordResponse.success {
                        if let records = dietRecordResponse.data {
                            completion(.success(records))
                        } else {
                            completion(.success([]))
                        }
                    } else {
                        completion(.failure(NSError(domain: "FoodAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "请求失败"])))
                    }
                    
                case .failure(let error):
                    print("创建饮食记录请求失败: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        } catch {
            print("编码请求体失败: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}
