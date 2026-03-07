//
//  NetworkDataHelper.swift
//  NetworkDataHelper
//
//  Created by Muthuraj Muthulingam on 28/12/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public protocol MMLoggingRules {
    var enableLogging: Bool { get set }
}

public protocol MMNetworkRules {
    var url:URL { get set }
}

public protocol MMRequestRules: MMNetworkRules {
    var parameters: MMParameters? { get set }
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
    var rawData: Data? { get set }
    var type: Type { get set }
}

public enum MMParameterValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

public typealias MMParameters = [String: MMParameterValue]

public enum MMRequestMethod:String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case delete = "DELETE"
}

public struct MMRequest: MMNetworkRules, Sendable {
    public var url: URL
    var parameters: MMParameters?
    var method: MMRequestMethod
    var responseType: Type
    var timeout: Double = 60 // default
    var headers: [String:String]?
    
    public init(from url: URL,
                params: MMParameters?,
                method: MMRequestMethod,
                responseType: Type,
                timeout: Double,
                headers: [String:String]?) {
        self.url = url
        self.parameters = params
        self.method = method
        self.responseType = responseType
        self.timeout = timeout
        self.headers = headers
    }
}

extension MMRequest {
    func asURLRequest(enableLogging: Bool) -> URLRequest {
        var finalRequest = URLRequest(url: self.url,
                                      cachePolicy: .reloadIgnoringLocalCacheData,
                                      timeoutInterval: self.timeout)
        finalRequest.allHTTPHeaderFields = headers
        
        if let paramsDict = parameters {
            let urlString = getURLString(fromParams: paramsDict)
            if method == .get && urlString.count > 0,
               let finalURL = URL(string: "\(url.absoluteString)?\(urlString)") {
                finalRequest.url = finalURL
            } else {
                let jsonBody = getJSONBody(fromParams: paramsDict)
                finalRequest.httpBody = jsonBody.getJSONData()
            }
        }
        
        finalRequest.httpMethod = method.rawValue
        
        if enableLogging, let urlString = finalRequest.url?.absoluteString {
            print("====================================================")
            print("Detailed URL Request")
            print("URL: \(urlString)")
            print("Parameters: \(String(describing: parameters))")
            print("Request Type: \(method.rawValue)")
            print("Headers : \(headers ?? ["NULL":"NULL"])")
            print("====================================================")
        }
        
        return finalRequest
    }
    
    private func getURLString(fromParams params: MMParameters) -> String {
        var urlString = ""
        for (key, value) in params {
            urlString += "\(key)=\(stringValue(from: value))&"
        }
        if !urlString.isEmpty {
            urlString.removeLast()
        }
        return urlString
    }
    
    private func getJSONBody(fromParams params: MMParameters) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in params {
            switch value {
            case .string(let s): result[key] = s
            case .int(let i): result[key] = i
            case .double(let d): result[key] = d
            case .bool(let b): result[key] = b
            }
        }
        return result
    }
    
    private func stringValue(from value: MMParameterValue) -> String {
        switch value {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        }
    }
}

public struct MMResponse: MMResponseRules, Sendable {
    public var error: Error?
    public var rawData: Data?
    public var type: Type
    
    public init(rawData: Data?, type: Type, error: Error?) {
        self.rawData = rawData
        self.type = type
        self.error = error
    }
}

// MARK: - Dictionary Extentions
public extension Dictionary {
    func getJSONData() -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
        } catch _ {
            return nil
        }
    }
}

// Custom class to enable logging
class MMLogOperation: Operation, MMLoggingRules {
    public var enableLogging: Bool
    
    init(with enableLogging: Bool) {
        self.enableLogging = enableLogging
        super.init()
    }
}

