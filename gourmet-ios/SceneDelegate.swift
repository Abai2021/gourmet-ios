//
//  SceneDelegate.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/30.
//

import UIKit
import Alamofire
import SwiftyJSON

// 用户默认值键
struct UserDefaultsKeysConstants {
    static let user = "com.gourmet.user"
    static let token = "com.gourmet.user.token"
    static let tokenExpiry = "com.gourmet.user.token.expiry"
}

// 导入 UserDefaultsKeys 和 LoginService
extension SceneDelegate {
    // 检查 token 并获取用户信息
    func checkTokenAndGetUserInfo() {
        // 检查 token 是否存在
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeysConstants.token), !token.isEmpty {
            // 获取用户信息
            getUserInfo(token: token)
        }
    }
    
    // 获取用户信息
    func getUserInfo(token: String) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "User-Agent": "Gourmet iOS",
            "Accept": "*/*",
            "Connection": "keep-alive"
        ]
        
        let url = "https://gourmet.pfcent.com/api/v1/users"
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseData { [weak self] response in
                switch response.result {
                case .success(let data):
                    // 尝试解析响应
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success,
                       let userData = json["data"] as? [String: Any] {
                        
                        // 创建用户对象
                        let user = self?.createUser(from: userData)
                        
                        // 保存用户信息
                        self?.saveUser(user)
                        
                        // 发送通知
                        if let user = user {
                            print("获取用户信息成功: \(user.nickname)")
                            
                            // 发送通知，通知用户信息已更新
                            let notificationName = Notification.Name("com.gourmet.userLoggedIn")
                            NotificationCenter.default.post(name: notificationName, object: nil)
                            
                            // 由于 SideMenuViewController 会在收到通知时自动调用 updateUserInfoDisplay 方法
                            // 所以这里不需要在通知中包含用户信息
                        }
                    } else {
                        print("获取用户信息失败: 无法解析响应")
                    }
                    
                case .failure(let error):
                    print("获取用户信息失败: \(error.localizedDescription)")
                    
                    // 检查是否是 401 错误
                    if let afError = error.asAFError,
                       let response = afError.responseCode,
                       response == 401 {
                        // 清除无效的 token
                        self?.clearUserData()
                        
                        // 发送通知，通知用户需要重新登录
                        let notificationName = Notification.Name("com.gourmet.userLoggedOut")
                        NotificationCenter.default.post(name: notificationName, object: nil)
                    }
                }
            }
    }
    
    // 创建用户对象
    func createUser(from userData: [String: Any]) -> UserInfo {
        let id = UserDefaults.standard.object(forKey: "com.gourmet.user.id") as? Int ?? 0
        let nickname = userData["nickname"] as? String ?? "未知用户"
        let avatar = userData["avatar"] as? String ?? ""
        let gender = userData["gender"] as? Int ?? 0
        let region = userData["region"] as? String ?? ""
        let uuid = userData["uuid"] as? String ?? ""
        
        return UserInfo(
            id: id,
            nickname: nickname,
            avatar: avatar.isEmpty ? nil : avatar,
            email: nil,
            gender: gender,
            region: region.isEmpty ? nil : region,
            uuid: uuid.isEmpty ? nil : uuid
        )
    }
    
    // 保存用户信息
    func saveUser(_ user: UserInfo?) {
        guard let user = user else { return }
        
        // 保存用户 ID
        UserDefaults.standard.set(user.id, forKey: "com.gourmet.user.id")
        
        // 编码用户对象
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeysConstants.user)
        }
    }
    
    // 清除用户数据
    func clearUserData() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeysConstants.token)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeysConstants.tokenExpiry)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeysConstants.user)
        UserDefaults.standard.removeObject(forKey: "com.gourmet.user.id")
    }
}

// 用户模型
struct UserInfo: Codable {
    var id: Int
    var nickname: String
    var avatar: String?
    var email: String?
    var gender: Int
    var region: String?
    var uuid: String?
    
    // 为了兼容性，添加一些计算属性
    var name: String { return nickname }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window with the windowScene
        window = UIWindow(windowScene: windowScene)
        
        // Set the TabBarController as the root view controller
        let tabBarController = TabBarController()
        window?.rootViewController = tabBarController
        
        // Make the window visible
        window?.makeKeyAndVisible()
        
        // 检查 token 并获取用户信息
        checkTokenAndGetUserInfo()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // 检查 token 并获取用户信息
        checkTokenAndGetUserInfo()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
