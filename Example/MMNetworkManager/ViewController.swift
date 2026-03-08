//
//  ViewController.swift
//  MMNetworkManager
//
//  Created by Muthuraj Muthulingam on 09/16/2018.
//  Copyright (c) 2018 Muthuraj Muthulingam. All rights reserved.
//

import UIKit
import MMNetworkManager

let kURLString = "http://www.mocky.io/v2/5a87a7b63200004a00f4e9a3"

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // reachablity  check
        debugPrint("Network Status : \(MMNetworkManager.shared.isNetworkReachable)")
        MMNetworkManager.shared.startNetworkStatusMonitoring()
        Task {
            for await isConnect in MMNetworkManager.shared.networkStatusSequence() {
                debugPrint("Status Change :\(isConnect)")
            }
        }
        loadDataFromServer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadDataFromServer() {
        guard let url = URL(string: kURLString) else { return }
        let request = MMRequest(from: url, params: nil, method: .get, responseType: .json, timeout: 30, headers: nil)
        Task {
            let (response, _) = await request.execute()
            debugPrint("URL Response : \(response) and Error : \(String(describing: response.error))")
        }
    }
}

