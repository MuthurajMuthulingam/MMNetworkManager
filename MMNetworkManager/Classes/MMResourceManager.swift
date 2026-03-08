//
//  NetworkResourceHelper.swift
//  NetworkResourceHelper
//
//  Created by Muthuraj Muthulingam on 07/01/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public struct MMNetworkResource: MMNetworkRules, MMResponseRules, Sendable {
    public var error: Error?
    public var rawData: Data?
    public var type: Type
    public var url: URL
    
    public init(rawData: Data?, type: Type, url: URL, error: Error?) {
        self.rawData = rawData
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

/** Helper class to retrieve resources from the network,
  * caching them in memory when appropriate.
  */
final class MMResourceManager : MMLogOperation {
    
    var needsProgressReport: Bool
    fileprivate let resource:MMNetworkResource
    fileprivate let resourceOperation:ResourceOperationType
    
    // Designated initializer
    public init(with resource:MMNetworkResource,toPerform operation:ResourceOperationType, enableLogging: Bool = true, needsProgressReport: Bool = false) {
        self.resource = resource
        self.resourceOperation = operation
        self.needsProgressReport = needsProgressReport
        super.init(with: enableLogging)
    }
    
    public func resultResource(WithData data:Data?, oldResource:MMNetworkResource, error: Error?) -> MMNetworkResource {
        var newResource = oldResource
        newResource.rawData = data
        newResource.error = error
        return newResource
    }
    
    // MARK: - Async API
    func perform() async -> MMNetworkResource {
        switch resourceOperation {
        case .upload:
            return await uploadResource()
        case .download:
            return await downloadResource()
        }
    }
    
    private func downloadResource() async -> MMNetworkResource {
        // get Resource from inMemory cache
        if let data = MMResourceCache.shared.data(for: resource.url.absoluteString) {
            // Resource available in Memory, no need to ask for network Resource
            return resultResource(WithData: data, oldResource: resource, error: nil)
        }
        
        let session = URLSession(configuration: .ephemeral)
        if enableLogging {
            print("Resource URL : \(resource.url.absoluteString)")
        }
        do {
            let (data, _) = try await session.data(from: resource.url)
            _ = MMResourceCache.shared.store(data: data, for: resource.url.absoluteString)
            return resultResource(WithData: data, oldResource: resource, error: nil)
        } catch {
            return resultResource(WithData: nil, oldResource: resource, error: error)
        }
    }
    
    private func uploadResource() async -> MMNetworkResource {
        guard let dataToBeUploaded = resource.rawData else {
            return resultResource(WithData: nil, oldResource: resource, error: nil)
        }
        let session = URLSession(configuration: .default)
        do {
            _ = try await session.upload(for: URLRequest(url: resource.url), from: dataToBeUploaded)
            return resultResource(WithData: nil, oldResource: resource, error: nil)
        } catch {
            return resultResource(WithData: nil, oldResource: resource, error: error)
        }
    }
}

// MARK: - Async convenience
public extension MMRequest {
    public func execute() async -> (MMResponse, MMRequest) {
        await MMNetworkManager.shared.perform(Request: self)
    }
}

public extension MMNetworkResource {
    func execute(operation: ResourceOperationType = .download,
                 needsProgressReporting: Bool = true) async -> MMNetworkResource {
        await MMNetworkManager.shared.performResource(self,
                                                      operation: operation,
                                                      needsProgressReporting: needsProgressReporting)
    }
}

// MARK: - UIImage view Extension
@MainActor
extension UIImageView {
    public func mm_setImage(from url: URL) {
        // create an image resource
        let imageResource = MMNetworkResource(rawData: nil, type: .image, url: url, error: nil)
        Task { @MainActor in
            let resultResource = await imageResource.execute()
            if resultResource.type == .image,
               let data = resultResource.rawData,
               url == resultResource.url,
               let image = UIImage(data: data) {
                self.image = image
            }
        }
    }
}
