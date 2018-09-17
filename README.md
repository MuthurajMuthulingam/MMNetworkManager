# MMNetworkManager
  Typical layer of every iOS application is to deal with network for various needs like,
   - Requesting response from Remote API
   - Requesting resources like image, PDF, any other types of document
   
   MMNetworkManger solves all these requirements for an app
  
[![CI Status](https://img.shields.io/travis/Muthuraj Muthulingam/MMNetworkManager.svg?style=flat)](https://travis-ci.org/Muthuraj Muthulingam/MMNetworkManager)
[![Version](https://img.shields.io/cocoapods/v/MMNetworkManager.svg?style=flat)](https://cocoapods.org/pods/MMNetworkManager)
[![License](https://img.shields.io/cocoapods/l/MMNetworkManager.svg?style=flat)](https://cocoapods.org/pods/MMNetworkManager)
[![Platform](https://img.shields.io/cocoapods/p/MMNetworkManager.svg?style=flat)](https://cocoapods.org/pods/MMNetworkManager)

# Purpose
 -  Provides three sub modules
 -  Network Resource Helper
      - Supports resources including Image,PDF,Word
      - Caches the loaded data and return it on the go
      - Asynchrounous execution of resource request
      - Progress reporting
      - Downloading/Uploading of resources
 -   Network Request Helper
      - Simple network data requests
      - Supports response formats including JSON,XML
      - Asynchrounous requests handling
 -  Network Manager
      - Manages data and resource requests
      - Supports multiple requests on the go

# Usage
 -  Please refer a demo project attached

## Installation

MMNetworkManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MMNetworkManager'
```

## Author

Muthuraj Muthulingam, muthurajmuthulingam@gmail.com

## License

MMNetworkManager is available under the MIT license. See the LICENSE file for more info.
