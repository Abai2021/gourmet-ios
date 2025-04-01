//
//  UserManager.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation
import AuthenticationServices
import Alamofire

// Notification names
extension Notification.Name {
    static let userLoggedIn = Notification.Name("com.gourmet.userLoggedIn")
    static let userLoggedOut = Notification.Name("com.gourmet.userLoggedOut")
    static let userProfileUpdated = Notification.Name("com.gourmet.userProfileUpdated")
}

class UserManager: NSObject {
    static let shared = UserManager()
    
    private(set) var currentUser: User?
    
    private override init() {
        super.init()
        loadUserFromDefaults()
    }
    
    // MARK: - User data management
    private func loadUserFromDefaults() {
        currentUser = UserDefaultsManager.shared.getObject(forKey: UserDefaultsKeys.user)
        
        if currentUser == nil {
            // Create a new user object if none exists
            currentUser = User()
            currentUser?.deviceId = UserDefaultsManager.shared.getDeviceId()
            saveUserToDefaults()
        }
    }
    
    private func saveUserToDefaults() {
        if let user = currentUser {
            UserDefaultsManager.shared.saveObject(user, forKey: UserDefaultsKeys.user)
        }
    }
    
    // MARK: - Authentication
    func isLoggedIn() -> Bool {
        return currentUser?.isLoggedIn ?? false
    }
    
    func login(with authorizationCode: String, completion: @escaping (Bool, Error?) -> Void) {
        let deviceId = UserDefaultsManager.shared.getDeviceId()
        
        DataManager.dataProvider.userAuth(authorizationCode: authorizationCode, deviceId: deviceId) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            if let authResponse = data as? AuthResponse {
                // Update user with auth response
                if self.currentUser == nil {
                    self.currentUser = User()
                    self.currentUser?.deviceId = deviceId
                }
                
                self.currentUser?.updateWithAuth(auth: authResponse)
                self.saveUserToDefaults()
                
                // Notify that user logged in
                NotificationCenter.default.post(name: .userLoggedIn, object: nil)
                
                // Fetch user profile
                self.fetchUserProfile()
                
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "com.gourmet.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
            }
        }
    }
    
    func logout() {
        currentUser?.logout()
        saveUserToDefaults()
        
        // Notify that user logged out
        NotificationCenter.default.post(name: .userLoggedOut, object: nil)
    }
    
    // MARK: - User profile
    func fetchUserProfile(completion: ((Bool, Error?) -> Void)? = nil) {
        guard isLoggedIn() else {
            completion?(false, NSError(domain: "com.gourmet.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        DataManager.dataProvider.userData { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                completion?(false, error)
                return
            }
            
            if let userProfile = data as? UserProfile {
                self.currentUser?.updateWithProfile(profile: userProfile)
                self.saveUserToDefaults()
                
                // Notify that user profile was updated
                NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
                
                completion?(true, nil)
            } else {
                completion?(false, NSError(domain: "com.gourmet.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid profile format"]))
            }
        }
    }
    
    // MARK: - Apple Sign In
    func performAppleSignIn(from viewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = viewController as? ASAuthorizationControllerPresentationContextProviding
        authorizationController.performRequests()
        
        // Store completion handler for later use
        self.signInCompletion = completion
    }
    
    // Temporary storage for completion handler
    private var signInCompletion: ((Bool, Error?) -> Void)?
}

// MARK: - ASAuthorizationControllerDelegate
extension UserManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // 获取用户信息
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("Apple 用户 ID: \(userIdentifier)")
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                print("用户姓名: \(givenName) \(familyName)")
            }
            if let email = email {
                print("用户邮箱: \(email)")
            }
            
            // 这里应该调用你的服务器 API 进行登录
            // 由于我们没有实际的服务器，这里模拟登录成功
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.signInCompletion?(true, nil)
                self.signInCompletion = nil
            }
        } else {
            signInCompletion?(false, NSError(domain: "com.gourmet.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get authorization code"]))
            signInCompletion = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInCompletion?(false, error)
        signInCompletion = nil
    }
}
