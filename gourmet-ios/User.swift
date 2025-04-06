//
//  User.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation
import Alamofire

// Auth response from server
struct AuthResponse: Codable {
    let accessToken: String
    let avatar: String
    let email: String
    let expiredAt: String
    let gender: Int
    let id: Int
    let nickname: String
    let provider: String
    let region: String
}

// User profile response from server
struct UserProfile: Codable {
    let uuid: String
    let nickname: String
    let avatar: String
    let gender: Int
    let region: String
}

// User class that combines auth and profile information
class User: Codable {
    var accessToken: String = ""
    var deviceId: String = ""
    var isLoggedIn: Bool = false
    
    // User profile information
    var uuid: String = ""
    var nickname: String = ""
    var avatar: String = ""
    var gender: Int = 0
    var region: String = ""
    
    static var _current: User?
    
    class func current() -> User {
        if _current != nil { return _current! }
        let user: User? = UserDefaultUtils.shared.fetchObject(UserDefaultsKeys.user)
        if user != nil {
            _current = user
            return _current!
        }
        _current = User()
        _current!.deviceId = UserDefaultUtils.shared.getDeviceId()
        UserDefaultUtils.shared.saveObject(_current, UserDefaultsKeys.user)
        return _current!
    }
    
    func saveToCurrent() {
        let current = User.current()
        current.accessToken = self.accessToken
        current.deviceId = self.deviceId
        current.isLoggedIn = self.isLoggedIn
        current.uuid = self.uuid
        current.nickname = self.nickname
        current.avatar = self.avatar
        current.gender = self.gender
        current.region = self.region
        UserDefaultUtils.shared.saveObject(current, UserDefaultsKeys.user)
    }
    
    // Initialize with auth response
    func updateWithAuth(auth: AuthResponse) {
        self.accessToken = auth.accessToken
        self.nickname = auth.nickname
        self.avatar = auth.avatar
        self.gender = auth.gender
        self.region = auth.region
        self.isLoggedIn = true
    }
    
    // 检查 token 是否有效
    static func isTokenValid() -> Bool {
        guard let tokenExpiryString = UserDefaults.standard.string(forKey: UserDefaultsKeys.tokenExpiry),
              let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token),
              !token.isEmpty else {
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        guard let expiryDate = dateFormatter.date(from: tokenExpiryString) else {
            return false
        }
        
        return expiryDate > Date()
    }
    
    // 从 UserDefaults 加载用户信息
    static func load() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: UserDefaultsKeys.user) else {
            return nil
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: userData)
            return user
        } catch {
            print("Error decoding user: \(error)")
            return nil
        }
    }
    
    // Update with user profile
    func updateWithProfile(profile: UserProfile) {
        self.uuid = profile.uuid
        self.nickname = profile.nickname
        self.avatar = profile.avatar
        self.gender = profile.gender
        self.region = profile.region
        self.saveToCurrent()
    }
    
    // Reset user data on logout
    func logout() {
        self.accessToken = ""
        self.isLoggedIn = false
        self.saveToCurrent()
    }
    
    // Check if token is valid
    static func isTokenValid() -> Bool {
        let user = User.current()
        return user.isLoggedIn && !user.accessToken.isEmpty
    }
    
    class func isLogin() -> Bool {
        return User.current().isLoggedIn
    }
    
    class func syncData() {
        DataManager.dataProvider.userData { (data, error) in
            if let error = error {
                if let afError = error as? AFError, afError.responseCode == 401 {
                    User.current().logout()
                    NotificationCenter.default.post(name: .userLoggedOut, object: nil)
                }
                return
            }
            if let userProfile = data as? UserProfile {
                let user = User.current()
                user.updateWithProfile(profile: userProfile)
                NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
            }
        }
    }
}
