//
//  NetworkDataHelper.swift
//  NetworkDataHelper
//
//  Created by Muthuraj Muthulingam on 28/12/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public typealias MMResponseHandler = ((_ response:MMResponse,_ request: MMRequest) -> Void)

public protocol MMLoggingRules {
    var enableLogging: Bool { get set }
}

public protocol MMNetworkRules {
    var url:URL { get set }
}

public protocol MMRequestRules: MMNetworkRules {
    var parameters:[String:Any]? { get set }
    var method:MMRequestMethod { get set }
    var responseType:Type { get set }
    var timeout:Double { get set }
    var headers:[String:String]? { get set }
}

public protocol MMNetworkResponseRules {
    var rawData: Data? { get set }
    var error: Error? { get set }
}

public protocol MMResponseRules: MMNetworkResponseRules {
    var rawData:Data? { get set }
    var formattedData:AnyObject? { get set }
    var type:Type { get set }
    
}

public enum MMRequestMethod:String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
}

public struct MMRequest:MMNetworkRules {
    public var url:URL
    var parameters:[String:Any]?
    var method:MMRequestMethod
    var responseType:Type
    var timeout:Double = 60 // default
    var headers:[String:String]?
    
    public init(from url:URL,
                params:[String:Any]?,
                method:MMRequestMethod,
                responseType:Type,
                timeout:Double,
                headers:[String:String]?) {
        self.url = url
        self.parameters = params
        self.method = method
        self.responseType = responseType
        self.timeout = timeout
        self.headers = headers
    }
}

public struct MMResponse:MMResponseRules {
    public var error: Error?
    public var rawData:Data?
    public var formattedData:AnyObject?
    public var type:Type
    
    public init(rawData:Data?, formattedData:AnyObject?, type:Type, error: Error?) {
        self.rawData = rawData
        self.formattedData = formattedData
        self.type = type
        self.error = error
    }
}

/**
 * Helper class to handle Remote Data
 * Process any type of request
 * handles remote data
 * executes network calls in different thread asynchrounouesly
 * handles multiple request and process it in parallel way
 */
public class MMRequestManager: MMLogOperation {
    private let request:MMRequest
    // completion Handler
    public var completionHandler: MMResponseHandler?
    
    // designated initializer
    public init(withRequest request:MMRequest, LogEnabled: Bool = true) {
        self.request = request
        super.init(with: LogEnabled)
        queuePriority = .high
        qualityOfService = .background
    }
    
    //MARK: - Private Helpers
    private func frameRequest() -> URLRequest {
        var finalRequest = URLRequest(url: self.request.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.request.timeout)
        // set headers if Any
        finalRequest.allHTTPHeaderFields = request.headers
        guard let paramsDict = request.parameters else {
            finalRequest.httpMethod = self.request.method.rawValue
            return finalRequest
        }
        let urlString = getURLString(fromParams: paramsDict)
        if request.method == .get && urlString.count > 0,
           let finalURL = URL(string: "\(request.url.absoluteString)?\(urlString)")  { // append it by framing actual request
           finalRequest.url = finalURL
        } else { // set parameters as JSON Body to request
            finalRequest.httpBody = paramsDict.getJSONData()
        }
        // set method
        finalRequest.httpMethod = request.method.rawValue
        // log request if needed
        if enableLogging {
            print("====================================================")
            print("Detailed URL Request")
            print("URL: \(finalRequest.url?.absoluteString ?? "NULL")")
            print("Parameters: \(paramsDict)")
            print("Request Type: \(request.method.rawValue)")
            print("Headers : \(request.headers ?? ["NULL":"NULL"])")
            print("====================================================")
        }
        return finalRequest
    }
    
    private func getURLString(fromParams params:[String:Any]) -> String {
        var urlString = ""
        for key in params.keys {
            if let value = params[key] {
               urlString += "\(key)=\(String(describing:value))&"
            }
        }
        // trim last char
        urlString.removeLast()
        return urlString
    }
    
    private func execute() {
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: frameRequest()) {(data, response, error) in
            var response = MMResponse(rawData: nil, formattedData: nil, type: self.request.responseType, error: error)
            guard let dataInfo = data else {
                self.completionHandler?(response, self.request)
                return }
            response.rawData = dataInfo
            if self.request.responseType == .json {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: dataInfo, options: .mutableContainers) as AnyObject
                    response.formattedData = jsonObject
                    self.completionHandler?(response, self.request)
                } catch let error {
                    response.error = error
                    self.completionHandler?(response, self.request)
                }
            } else { // other response types
                self.completionHandler?(response, self.request)
            }
            }.resume()
    }
    
    //MARK: - Public Helpers
    override public func main() {
        // execute the request
        execute()
    }
}

// MARK: - Dictionary Extentions
public extension Dictionary {
    public func getJSONData() -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
        } catch _ {
            return nil
        }
    }
}

//MARK: - Authontication Challenge Delegates
extension MMRequestManager : URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Handle Authontication Challenge
    }
}

// Custom class to enable logging
public class MMLogOperation: Operation, MMLoggingRules {
    public var enableLogging: Bool
    
    init(with enableLogging: Bool) {
        self.enableLogging = enableLogging
        super.init()
    }
}

