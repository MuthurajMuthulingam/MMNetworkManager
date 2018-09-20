//
//  ResourceCache.swift
//  DataCache
//
//  Created by Muthuraj Muthulingam on 07/01/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public enum ResourceCacheScope {
    case memory
    case disk
    case memoryOrDisk
}

/**
 * Helper class to manage storing Image (handling only images for now)
 * Uses NSCache to store image (i.e, stores in memory)
 * Has limit to store number of images
 * NSCache is effienct in terms of speed, handling memory pressure
 */
public class MMResourceCache {

    /// shared Instance of resourceCache
    public static let shared:MMResourceCache = MMResourceCache()
    
    // made private to avoid calling from other classes
    private init() {
        // setting default count
        resourceCache.countLimit = 30
    }
    
    private let resourceCache = NSCache<NSString, NSData>()
    
    // default will be resources cached using NSCache for better performance
    private var scope: ResourceCacheScope = .memory
    
    //MARK: Public methods
    /// Setting limit to storage
    ///
    /// - Parameter count: number of maximum count
    public func setLimit(count:Int) {
        resourceCache.countLimit = count
    }
    
    public func setResourceCacheScope(scope: ResourceCacheScope) {
        self.scope = scope
    }

    /// Stores Image instance for key
    ///
    /// - Parameters:
    ///   - imageInstance: Image instance to be stored
    ///   - key: key to which the image to be stored
    public func store(data:Data, for key:String) -> Bool {
        return store(data: data, for: key, with: scope)
    }
    
    /// retrieve resource if available
    /// - @discuission it check for resource from NSCache and Cache directory
    /// - Parameter key: key to which image is stored
    /// - Returns: image Instance if available otherwise nil
    public func data(for key:String) -> Data? {
        // retrive from nscache if available
        if let data = resourceCache.object(forKey: key as NSString) {
            return data as Data
        }
        do {
            if let data = try retriveData(fromCacheDirectory: key) { // try retrive from Cache Directory
               return data
            }
        } catch let error {
            debugPrint("Error while retriving data from Cache Directory : \(error.localizedDescription)")
        }
        return nil // not found
    }
    
    // MARK: - Private Helpers
    private func store(data: Data, for key: String, with scope: ResourceCacheScope) -> Bool {
        var status = false
        switch scope {
        case .memory:
            resourceCache.setObject(data as NSData, forKey: key as NSString)
            status = true // assuming it got stored
        case .disk:
            // store it to cache directory
            status = storeData(toCacheDirectory: data as NSData, for: key)
            break
        case .memoryOrDisk:
            // store it to cache directory
            status = storeData(toCacheDirectory: data as NSData, for: key)
            break
        }
        return status
    }
    
    private func storeData(toCacheDirectory data: NSData, for key: String) -> Bool {
        if let actualResourcePath = getCacheDirectoryPath(filePath: key) {
            return data.write(toFile: actualResourcePath, atomically: true)
        }
        return false
    }
    
    private func retriveData(fromCacheDirectory key: String) throws -> Data? {
        if let actualResourcePath = getCacheDirectoryPath(filePath: key),
            FileManager.default.fileExists(atPath: actualResourcePath) {
            return try Data(contentsOf: URL(fileURLWithPath: actualResourcePath))
        }
        return nil
    }
    
    private func getCacheDirectoryPath(filePath: String) -> String? {
        if let cacheDirectoryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first as NSString? {
            let actualResourcePath = cacheDirectoryPath.appendingPathComponent(filePath) as String
            return actualResourcePath
        }
        return nil
    }
}
