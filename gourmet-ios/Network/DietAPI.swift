//
//  DietAPI.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/6.
//

import Foundation
import Alamofire

class DietAPI {
    static let shared = DietAPI()
    
    private init() {}
    
    // 获取指定日期的饮食记录
    func fetchDietRecords(date: String, completion: @escaping (Result<[DietRecord], Error>) -> Void) {
        let urlString = "\(APIConst.BaseUrl)/api/v1/directs?date=\(date)"
        
        print("API请求: 获取饮食记录")
        print("请求URL: \(urlString)")
        print("当前用户登录状态: \(User.isTokenValid() ? "已登录" : "未登录")")
        
        guard let url = URL(string: urlString) else {
            print("API错误: 无效URL")
            completion(.failure(NSError(domain: "com.gourmet.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var headers: HTTPHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "User-Agent": "GourmetApp/1.0"
        ]
        
        // 如果用户已登录，添加认证头
        if User.isTokenValid() {
            if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
                print("API: 添加认证头 Bearer token")
                headers["Authorization"] = "Bearer \(token)"
            } else {
                print("API警告: 用户登录但未找到token")
            }
        } else {
            print("API: 用户未登录，无法添加认证头")
        }
        
        print("API: 发送GET请求")
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseData { response in
                // 分析原始响应数据
                print("API响应: 状态码=\(response.response?.statusCode ?? 0)")
                
                if let data = response.data {
                    print("API响应: 数据大小=\(data.count)字节")
                    // 尝试解析为字符串查看可能的错误消息
                    if let responseString = String(data: data, encoding: .utf8) {
                        if responseString.count < 300 { // 防止日志过长
                            print("API原始响应: \(responseString)")
                        } else {
                            print("API原始响应: (太长，只显示前100字符) \(responseString.prefix(100))...")
                        }
                    }
                } else {
                    print("API响应: 无数据")
                }
                
                if let error = response.error {
                    print("API错误: \(error.localizedDescription)")
                }
            }
            .responseDecodable(of: DietRecordResponse.self) { response in
                switch response.result {
                case .success(let dietResponse):
                    if dietResponse.success {
                        if let records = dietResponse.data {
                            print("API请求成功: 返回\(records.count)条记录")
                            completion(.success(records))
                        } else {
                            print("API警告: 成功响应但没有数据")
                            completion(.success([]))  // 返回空数组
                        }
                    } else {
                        print("API错误: success=false, message=\(dietResponse.message ?? "无")")
                        completion(.failure(NSError(domain: "com.gourmet.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "API returned success=false: \(dietResponse.message ?? "")"])))
                    }
                case .failure(let error):
                    print("API解码错误: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
    
    // 删除指定的食物项
    func deleteFoodItem(recordId: Int, foodItemId: Int, completion: @escaping (Result<[DietRecord], Error>) -> Void) {
        let urlString = "\(APIConst.BaseUrl)/api/v1/directs?record_id=\(recordId)&food_item_id=\(foodItemId)"
        
        print("API请求: 删除食物项")
        print("请求URL: \(urlString)")
        print("当前用户登录状态: \(User.isTokenValid() ? "已登录" : "未登录")")
        
        guard let url = URL(string: urlString) else {
            print("API错误: 无效URL")
            completion(.failure(NSError(domain: "com.gourmet.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var headers: HTTPHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "User-Agent": "GourmetApp/1.0"
        ]
        
        // 如果用户已登录，添加认证头
        if User.isTokenValid() {
            if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
                print("API: 添加认证头 Bearer token")
                headers["Authorization"] = "Bearer \(token)"
            } else {
                print("API警告: 用户登录但未找到token")
            }
        } else {
            print("API: 用户未登录，无法添加认证头")
        }
        
        print("API: 发送DELETE请求")
        AF.request(url, method: .delete, headers: headers)
            .validate()
            .responseData { response in
                // 分析原始响应数据
                print("API响应: 状态码=\(response.response?.statusCode ?? 0)")
                
                if let data = response.data {
                    print("API响应: 数据大小=\(data.count)字节")
                    // 尝试解析为字符串查看可能的错误消息
                    if let responseString = String(data: data, encoding: .utf8) {
                        if responseString.count < 300 { // 防止日志过长
                            print("API原始响应: \(responseString)")
                        } else {
                            print("API原始响应: (太长，只显示前100字符) \(responseString.prefix(100))...")
                        }
                    }
                } else {
                    print("API响应: 无数据")
                }
                
                if let error = response.error {
                    print("API错误: \(error.localizedDescription)")
                }
            }
            .responseDecodable(of: DietRecordResponse.self) { response in
                switch response.result {
                case .success(let dietResponse):
                    if dietResponse.success {
                        if let records = dietResponse.data {
                            print("API删除成功: 返回\(records.count)条记录")
                            completion(.success(records))
                        } else {
                            print("API警告: 成功响应但没有数据")
                            completion(.success([]))  // 返回空数组
                        }
                    } else {
                        print("API错误: success=false, message=\(dietResponse.message ?? "无")")
                        completion(.failure(NSError(domain: "com.gourmet.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "API returned success=false: \(dietResponse.message ?? "")"])))
                    }
                case .failure(let error):
                    print("API解码错误: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }
}
