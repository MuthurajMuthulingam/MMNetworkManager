//
//  NetworkManager.swift
//  NetworkHelper
//
//  Created by Muthuraj Muthulingam on 28/12/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public typealias ResourceCompletionBlock = ((_ resource:MMNetworkResource) -> Void)
public typealias NetworkStatusBlock = ((_ NetworkManager:MMNetworkManager, _ isNetworkReachable:Bool) -> Void)

public class MMNetworkManager {
    
    // shared instance
    public static let shared:MMNetworkManager = MMNetworkManager()
    
    // Reachablity
    public var isNetworkReachable:Bool {
        get {
            return (reachablity == nil) ? false : (reachablity?.isReachable)!
        }
    }

    /// Helps debugging by princting resource and resquest and response details
    public var enableLogging: Bool = false // default
    
    // Private request operation Queue
    public lazy var requestsQueue = OperationQueue()
    
    // Private resource request operation queue
    public lazy var resourceRequestsQueue = OperationQueue()
    
    // Notification to Network Changes
    public var networkStatusChanged:NetworkStatusBlock?
    
    //rechablity instance
    lazy var reachablity:MMReachability? = try! MMReachability(hostname: "Reachablity")
    
    //MARK: - Public Helpers
    public func perform(Request request:MMRequest,CompletionHandler completion:@escaping MMResponseHandler) {
        let requestHelper = MMRequestManager(withRequest: request)
        requestHelper.completionHandler = completion
        requestsQueue.addOperation(requestHelper)
    }
    
    /// Find and get Resource from Server if not available offline
    ///
    /// - Parameters:
    ///   - resource: resource information
    ///   - completion: completion handler will return on secondary thread
    public func getRemote(Resource resource:MMNetworkResource, needsProgressReporting progressReport: Bool, completion:@escaping ResourceCompletionBlock) {
        let resourceHelper = MMResourceManager(with: resource, toPerform: .download)
        resourceHelper.completionHandler = completion
        resourceRequestsQueue.addOperation(resourceHelper)
    }
    
    public func getSize() {
        print(class_getInstanceSize(MMNetworkManager.self))
    }
}

// Computed Properties
extension MMNetworkManager {
    public var requestsCount:Int {
        return requestsQueue.operationCount
    }
    
    public var resourceRequestCount:Int {
        return resourceRequestsQueue.operationCount
    }
}

//Reachablity Helper
extension MMNetworkManager {
    public func startNetworkStatusMonitoring() {
        do {
            try reachablity?.start()
            observeForFlagChanges()
        } catch let error {
            debugPrint("Error while start monitoring. \(error.localizedDescription)")
        }
    }
    
    public func stopNetworkMonitoring() {
        reachablity?.stop()
    }
    
    public func observeForFlagChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(notification:)), name: .flagsChanged, object: nil)
    }
    
    @objc
    private func handleNotification(notification:NSNotification) {
        if let reachablity = notification.object as? MMReachability {
            networkStatusChanged?(self, reachablity.isReachable)
        }
    }
}
