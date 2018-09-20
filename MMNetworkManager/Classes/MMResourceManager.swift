//
//  NetworkResourceHelper.swift
//  NetworkResourceHelper
//
//  Created by Muthuraj Muthulingam on 07/01/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public struct MMNetworkResource:MMNetworkRules, MMResponseRules {
    public var error: Error?
    public var rawData:Data?
    public var formattedData:AnyObject?
    public var type:Type
    public var url:URL
    
    public init(rawData:Data?,formattedData:AnyObject? , type:Type, url:URL, error: Error?) {
        self.rawData = rawData
        self.formattedData = formattedData
        self.type = type
        self.url = url
        self.error = error
    }
}

public enum Type {
    case image
    case pdf
    case json
    case word
}

public enum ResourceOperationType {
    case upload
    case download
}

/** Helper class to retrive resource from network,
  * Cache resource if already downloaded
  * retrive resource only if not available in cache
  * Uses NSCache to store resource in memory, not in disk
  * Have higher limits in resource counts
 */
public class MMResourceManager : MMLogOperation, ProgressReportRules {
    
    public var needsProgressReport: Bool
    fileprivate let resource:MMNetworkResource
    fileprivate let resourceOperation:ResourceOperationType
    
    // Designated initializer
    public init(with resource:MMNetworkResource,toPerform operation:ResourceOperationType, enableLogging: Bool = true, needsProgressReport: Bool = false) {
        self.resource = resource
        self.resourceOperation = operation
        self.needsProgressReport = needsProgressReport
        super.init(with: enableLogging)
        self.queuePriority = .high
        self.qualityOfService = .background
    }
    
    // result block
    public var completionHandler:ResourceCompletionBlock?
    // progress indicator
    public var progress:((_ networkResourceHelper:MMResourceManager, _ progress:CGFloat, _ resource:MMNetworkResource)->Void)?
    
    /// request resource over network
    ///
    /// - Parameter URL: URL of the resource resource
    private func requestNetworkResource() {
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: OperationQueue())
        if enableLogging {
           print("Resource URL : \(resource.url.absoluteString)")
        }
        session.downloadTask(with: resource.url).resume()
    }
    
    public func resultResource(WithData data:Data?, oldResource:MMNetworkResource, error: Error?) -> MMNetworkResource {
        var newResource = oldResource
        newResource.rawData = data
        if oldResource.type == .image, let unwrappedData = data {
           newResource.formattedData = UIImage(data: unwrappedData)
        }
        newResource.error = error
        return newResource
    }
    
    // MARK: - Public methods
    override public func main() {
        switch resourceOperation {
        case .upload:
            uploadResource()
        case .download:
            getResource()
        }
    }
    
    private func getResource() {
        // get Resource from inMemory cache
        if let data = MMResourceCache.shared.data(for: resource.url.absoluteString) {
            // Resource available in Memory, no need to ask for network Resource
            completionHandler?(resultResource(WithData: data, oldResource: resource, error: nil))
        } else {
            // resource not available inMemory
            // requaest resource from network, update resource in memory
            requestNetworkResource()
        }
    }
    
    private func uploadResource() {
        guard let dataToBeUploaded = resource.rawData else { return }
        let uploadSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        uploadSession.uploadTask(with: URLRequest(url: resource.url), from: dataToBeUploaded).resume()
    }
}

//MARK: - Data Download Task Process Delegate
extension MMResourceManager:URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if needsProgressReport {
            let percentage = CGFloat(bytesWritten/totalBytesExpectedToWrite)
            progress?(self,percentage,resource)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            do {
                let resourceData = try Data(contentsOf: location)
                // store it in cache
                _ = MMResourceCache.shared.store(data: resourceData, for: resource.url.absoluteString)
                completionHandler?(resultResource(WithData: resourceData, oldResource: resource, error: nil))
            } catch let error {
                completionHandler?(resultResource(WithData: nil, oldResource: resource, error: error))
            }
    }
}

//MARK: - Data Upload Task process delegate
extension MMResourceManager:URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if needsProgressReport {
            let percentage = CGFloat(bytesSent/totalBytesExpectedToSend)
            progress?(self,percentage,resource)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Completed test : \(String(describing: error))")
        completionHandler?(resultResource(WithData: nil, oldResource: resource, error: error))
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        debugPrint("upload status : \(String(describing: response.url))")
    }
}

// MARK: - Network Helper Rules
public protocol NetworkCallHelper {
     associatedtype T
    func execute(completion: T)
}

extension MMRequest: NetworkCallHelper {
    public typealias T = MMResponseHandler
    public func execute(completion: @escaping MMResponseHandler) {
        MMNetworkManager.shared.perform(Request: self, CompletionHandler: completion)
    }
}

extension MMNetworkResource: NetworkCallHelper {
    public typealias T = ResourceCompletionBlock
    public func execute(completion: @escaping ResourceCompletionBlock) {
        MMNetworkManager.shared.getRemote(Resource: self, needsProgressReporting: true, completion: completion)
    }
}

public protocol ProgressReportRules {
    var progress:((_ networkResourceHelper:MMResourceManager, _ progress:CGFloat, _ resource:MMNetworkResource)->Void)? { get }
    var needsProgressReport: Bool { get set }
}

// MARK: - UIImage view Extension
extension UIImageView {
    public func mm_setImage(from url: URL) {
        // create a image resource
        let imageResource = MMNetworkResource(rawData: nil, formattedData: nil, type: .image, url: url, error: nil)
        imageResource.execute { resultResource in
            if let imageData = resultResource.formattedData as? UIImage, // Image data
                url == resultResource.url { // both url remains same
                DispatchQueue.main.async {
                    self.image = imageData
                }
            }
        }
    }
}
