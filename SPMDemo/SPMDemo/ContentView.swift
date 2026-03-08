//
//  ContentView.swift
//  SPMDemo
//
//  Demo app consuming MMNetworkManager via Swift Package Manager
//

import SwiftUI
import MMNetworkManager

private let kURLString = "https://httpbin.org/get"

struct ContentView: View {
    @State private var networkStatus = "Checking..."
    @State private var responseText = "Tap to load"
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section("Network Status") {
                    HStack {
                        Text("Reachable")
                        Spacer()
                        Text(networkStatus)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("API Request") {
                    Button {
                        loadData()
                    } label: {
                        HStack {
                            Text("Fetch from httpbin.org")
                            Spacer()
                            if isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoading)

                    Text(responseText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("MMNetworkManager")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await setupNetworkMonitoring()
            }
        }
    }

    private func setupNetworkMonitoring() async {
        networkStatus = MMNetworkManager.shared.isNetworkReachable ? "Yes" : "No"
        MMNetworkManager.shared.startNetworkStatusMonitoring()

        Task {
            for await isReachable in MMNetworkManager.shared.networkStatusSequence() {
                networkStatus = isReachable ? "Yes" : "No"
            }
        }
    }

    private func loadData() {
        isLoading = true
        responseText = "Loading..."

        Task {
            defer { isLoading = false }
            guard let url = URL(string: kURLString) else {
                responseText = "Invalid URL"
                return
            }
            let request = MMRequest(
                from: url,
                params: nil,
                method: .get,
                responseType: .json,
                timeout: 30,
                headers: nil
            )
            let (response, _) = await request.execute()
            if let error = response.error {
                responseText = "Error: \(error.localizedDescription)"
            } else if let data = response.rawData, let json = String(data: data, encoding: .utf8) {
                responseText = String(json.prefix(500))
                if json.count > 500 {
                    responseText += "..."
                }
            } else {
                responseText = "No data"
            }
        }
    }
}

#Preview {
    ContentView()
}
