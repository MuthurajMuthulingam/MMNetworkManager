# SPMDemo

Demo application that consumes **MMNetworkManager** via Swift Package Manager.

## Setup

1. Open `SPMDemo.xcodeproj` in Xcode.
2. The project references MMNetworkManager as a **local package** (`../`).
3. Build and run on a simulator or device (iOS 18+).

## Features

- **Network status** – Displays reachability and listens for changes via `networkStatusSequence()`.
- **API request** – Fetches JSON from httpbin.org using `MMRequest.execute()`.

## Adding MMNetworkManager via SPM

This demo uses a local package reference. To add MMNetworkManager from a remote source:

1. In Xcode: **File → Add Package Dependencies**
2. Enter: `https://github.com/MuthurajMuthulingam/MMNetworkManager`
3. Add the `MMNetworkManager` product to your target.
