//
//  NetworkManager.swift
//  NetworkHelper
//
//  Created by Muthuraj Muthulingam on 28/12/17.
//  Copyright © 2017 Muthuraj Muthulingam. All rights reserved.
//

import UIKit

public typealias NetworkStatusBlock = (_ NetworkManager: MMNetworkManager, _ isNetworkReachable: Bool) async -> Void

@MainActor
public class MMNetworkManager {
    
    // shared instance
    public static let shared: MMNetworkManager = MMNetworkManager()

    // Reachablity
    public var isNetworkReachable: Bool {
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
    
    // Async network status listeners
    private var networkStatusContinuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    
    // Notification to Network Changes
    public var networkStatusChanged: NetworkStatusBlock?

    //reachability instance
    lazy var reachablity: MMReachability? = try! MMReachability(hostname: "Reachablity")

    //MARK: - Public Helpers
    public func perform(Request request: MMRequest) async -> (MMResponse, MMRequest) {
        let urlRequest = request.asURLRequest(enableLogging: enableLogging)
        let session = URLSession(configuration: .ephemeral)
        do {
            let (data, _) = try await session.data(for: urlRequest)
            let response = MMResponse(rawData: data, type: request.responseType, error: nil)
            return (response, request)
        } catch {
            let response = MMResponse(rawData: nil, type: request.responseType, error: error)
            return (response, request)
        }
    }
    
    /// Find and get Resource from Server if not available offline
    ///
    /// - Parameters:
    ///   - resource: resource information
    public func getRemoteResource(_ resource: MMNetworkResource,
                                  needsProgressReporting progressReport: Bool) async -> MMNetworkResource {
        await performResource(resource, operation: .download, needsProgressReporting: progressReport)
    }
    
    /// Perform a resource operation (upload or download).
    public func performResource(_ resource: MMNetworkResource,
                                operation: ResourceOperationType,
                                needsProgressReporting progressReport: Bool) async -> MMNetworkResource {
        let resourceHelper = MMResourceManager(with: resource,
                                               toPerform: operation,
                                               enableLogging: enableLogging,
                                               needsProgressReport: progressReport)
        return await resourceHelper.perform()
    }
    
    public func getSize() {
        print(class_getInstanceSize(MMNetworkManager.self))
    }
    
    /// Async sequence of network reachability changes.
    /// The sequence yields a Bool each time the network reachability changes.
    public func networkStatusSequence() -> AsyncStream<Bool> {
        let id = UUID()
        return AsyncStream { continuation in
            networkStatusContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                self?.networkStatusContinuations.removeValue(forKey: id)
            }
        }
    }
}

// Computed Properties
extension MMNetworkManager {
    public var requestsCount:Int {
        requestsQueue.operationCount
    }
    
    public var resourceRequestCount:Int {
        resourceRequestsQueue.operationCount
    }
}

//Reachablity Helper
extension MMNetworkManager {
    public func startNetworkStatusMonitoring() {
        do {
            try reachablity?.start()
            observeNetworkStatusChanges()
        } catch let error {
            debugPrint("Error while start monitoring. \(error.localizedDescription)")
        }
    }
    
    public func stopNetworkMonitoring() {
        reachablity?.stop()
    }
    
    public func observeNetworkStatusChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(notification:)), name: .networkStatusChanged, object: nil)
    }
    
    @objc
    private func handleNotification(notification: NSNotification) {
        guard let reachablity = notification.object as? MMReachability,
              let handler = networkStatusChanged else { return }
        
        Task { @MainActor in
            let isReachable = reachablity.isReachable
            await handler(self, isReachable)
            for continuation in networkStatusContinuations.values {
                continuation.yield(isReachable)
            }
        }
    }
}
