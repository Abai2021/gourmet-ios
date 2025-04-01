//
//  DataProvider.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

protocol DataProvider {
    func userAuth(authorizationCode: String, deviceId: String, _ completionHandler: CompletionHandler?)
    func userData(_ completionHandler: CompletionHandler?)
}
