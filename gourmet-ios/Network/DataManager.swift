//
//  DataManager.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

struct DataManager {
    static private var currentDataProvider: DataProvider = NetworkDataProvider()
    
    static func setDataProvider(dataProvider: DataProvider) {
        currentDataProvider = dataProvider
    }
    
    static var dataProvider: DataProvider {
        get {
            return currentDataProvider
        }
    }
}
