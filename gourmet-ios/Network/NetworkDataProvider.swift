//
//  NetworkDataProvider.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

final class NetworkDataProvider: DataProvider {
    
    func userAuth(authorizationCode: String, deviceId: String, _ completionHandler: CompletionHandler?) {
        self.processRequest(UserAuthRequest(authorizationCode: authorizationCode, deviceId: deviceId), completionHandler)
    }
    
    func userData(_ completionHandler: CompletionHandler?) {
        self.processRequest(UserDataRequest(), completionHandler)
    }
    
    // MARK: - Private methods
    private func processRequest(_ request: BaseRequest, _ completionHandler: CompletionHandler?) -> Void {
        self.executeRequest(request, completionHandler)
    }
    
    private func executeRequest(_ request: BaseRequest, _ completionHandler: CompletionHandler?) -> Void {
        if request.needsAccessToken() {
            // Set the Access Token to the request header
            request.setAccessToken()
        }
        
        NetworkProvider.shared.sendRequest(request) { (_ data: Any?, _ error: Error?) in
            completionHandler?(data, error)
        }
    }
}
