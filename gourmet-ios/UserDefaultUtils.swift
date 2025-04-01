//
//  UserDefaultUtils.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import UIKit

struct UserDefaultsKeys {
    static let user = "com.gourmet.user"
    static let deviceId = "com.gourmet.deviceId"
}

class UserDefaultUtils {
    // Shared Instance for the class
    static let shared = UserDefaultUtils()

    // Don't allow instances creation of this class
    private init() {}

    func saveObject<T: Codable>(_ object: T, _ key: String) {
        let dataEncoder = JSONEncoder()
        do {
            let data = try dataEncoder.encode(object)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            assertionFailure("Error encoding object of type \(T.self): \(error)")
        }
    }

    func fetchObject<T>(_ key: String) -> T? where T: Decodable {
        guard let savedItem = UserDefaults.standard.object(forKey: key) as? Data else { return nil}
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: savedItem)
        } catch {
            print("Error decoding object of type \(T.self): \(error)")
        }
        return nil
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
}
