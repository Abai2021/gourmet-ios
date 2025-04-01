//
//  UserDefaultsManager.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

struct UserDefaultsKeys {
    static let user = "com.gourmet.user"
    static let deviceId = "com.gourmet.deviceId"
}

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    // MARK: - Generic methods for Codable objects
    func saveObject<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error encoding object for key \(key): \(error)")
        }
    }
    
    func getObject<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error decoding object for key \(key): \(error)")
            return nil
        }
    }
    
    // MARK: - Device ID
    func getDeviceId() -> String {
        if let deviceId = UserDefaults.standard.string(forKey: UserDefaultsKeys.deviceId) {
            return deviceId
        } else {
            // Generate a new device ID if one doesn't exist
            let newDeviceId = UUID().uuidString
            UserDefaults.standard.set(newDeviceId, forKey: UserDefaultsKeys.deviceId)
            return newDeviceId
        }
    }
    
    // MARK: - Clear data
    func clearUserData() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.user)
    }
}
