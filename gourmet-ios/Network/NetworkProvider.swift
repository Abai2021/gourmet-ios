//
//  NetworkProvider.swift
//  gourmet-ios
//
//  Created by 魏展斌 on 2025/3/31.
//

import Foundation
import Alamofire
import SwiftyJSON

class NetworkProvider {
    
    static let shared = NetworkProvider()
    var alamofireManager: Alamofire.Session?
    
    // Don't allow instances creation of this class
    private init() {
        configureAlamofire()
    }
    
    func configureAlamofire() {
        let interceptor = GourmetRequestInterceptor()
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        
        alamofireManager = Session(configuration: configuration, interceptor: interceptor)
    }

    /**
     * Sends a request to the backend and returns the response (or an error) through the
     * CompletionHandler received.
     *
     * @param baseRequest
     *      BaseRequest to send to the backend.
     * @param completionHandler
     *      CompletionHandler that will receive the response from this request.
     */
    func sendRequest(_ baseRequest: BaseRequest, _ completionHandler: CompletionHandler?) -> Void {
        
        self.alamofireManager?.request(baseRequest).validate().responseData { response in
            let url = baseRequest.urlRequest.url?.description ?? ""
            print("Request URL: \(url)")
            
            switch response.result {
            case .success(let data):
                guard let completionHandler = completionHandler else { return }
                
                do {
                    let json = try JSON(data: data)
                    print("Response JSON: \(json)")
                    
                    if json["success"].boolValue {
                        if let dataObject = json["data"].object {
                            let jsonData = try JSONSerialization.data(withJSONObject: dataObject)
                            let responseData = baseRequest.parseNetworkResponse(jsonData)
                            completionHandler(responseData, nil)
                        } else {
                            completionHandler(nil, NSError(domain: "com.gourmet.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"]))
                        }
                    } else {
                        let errorMessage = json["message"].stringValue
                        completionHandler(nil, NSError(domain: "com.gourmet.error", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    completionHandler(nil, error)
                }
                
            case .failure(let error):
                print("Network error: \(error)")
                guard let completionHandler = completionHandler else { return }
                completionHandler(nil, error)
            }
        }
    }
}

class GourmetRequestInterceptor: RequestInterceptor {
    let maxRetries: Int = 3
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let adaptedRequest = urlRequest
        completion(.success(adaptedRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if let response = request.task?.response as? HTTPURLResponse,
           response.statusCode == 429,
           request.retryCount < maxRetries {
            // Add jitter to retry delay to prevent all clients from retrying at the same time
            let jitter = Double.random(in: 0...1)
            completion(.retryWithDelay(2.0 + jitter)) // retry after interval between 2-3 seconds
        } else {
            completion(.doNotRetry) // don't retry
        }
    }
}
