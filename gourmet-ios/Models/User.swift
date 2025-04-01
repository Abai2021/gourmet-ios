//
//  User.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

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
    
    // Initialize with auth response
    func updateWithAuth(auth: AuthResponse) {
        self.accessToken = auth.accessToken
        self.nickname = auth.nickname
        self.avatar = auth.avatar
        self.gender = auth.gender
        self.region = auth.region
        self.isLoggedIn = true
    }
    
    // Update with user profile
    func updateWithProfile(profile: UserProfile) {
        self.uuid = profile.uuid
        self.nickname = profile.nickname
        self.avatar = profile.avatar
        self.gender = profile.gender
        self.region = profile.region
    }
    
    // Reset user data on logout
    func logout() {
        self.accessToken = ""
        self.isLoggedIn = false
    }
}
