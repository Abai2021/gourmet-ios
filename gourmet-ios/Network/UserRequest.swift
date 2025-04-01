//
//  UserRequest.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

class UserAuthRequest: JsonRequest<AuthResponse> {
    init(authorizationCode: String, deviceId: String) {
        super.init(method: .post, urlPath: "\(APIConst.BaseUrl)/api/v1/auths/apple")
        
        let bodyParams: [String: String] = [
            "authorization_code": authorizationCode,
            "device_id": deviceId
        ]
        
        setBody(bodyParams)
    }
    
    override func needsAccessToken() -> Bool {
        return false
    }
}

class UserDataRequest: JsonRequest<UserProfile> {
    init() {
        super.init(method: .get, urlPath: "\(APIConst.BaseUrl)/api/v1/users")
    }
    
    override func needsAccessToken() -> Bool {
        return true
    }
}
