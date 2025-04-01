//
//  JsonRequest.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation

class JsonRequest<T: Codable>: BaseRequest {
    override func parseNetworkResponse(_ response: Any) -> Any? {
        guard let res = response as? Data else { return nil }
        return DecodingUtils.decodeData(res, to: T.self)
    }
}

class DecodingUtils {
    static func decodeData<T: Decodable>(_ data: Data, to type: T.Type) -> T? {
        let decoder = JSONDecoder()
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(df)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error decoding \(T.self): \(error)")
        }
        return nil
    }
}
