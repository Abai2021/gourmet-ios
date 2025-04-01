//
//  GlobalUserManager.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

// 全局访问用户管理器的函数
func getUserManager() -> UserManager {
    return UserManager.shared
}

// 全局访问用户登录状态的函数
func isUserLoggedIn() -> Bool {
    return UserManager.shared.isLoggedIn()
}

// 全局访问当前用户的函数
func getCurrentUser() -> User? {
    return UserManager.shared.currentUser
}
