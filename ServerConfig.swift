//
// ServerConfig.swift
//

import Foundation
import Combine

final class ServerConfig: ObservableObject {
    static let shared = ServerConfig()

    @Published var wsURL: String {
        didSet {
            UserDefaults.standard.set(wsURL, forKey: "ws_url")
        }
    }

    private init() {
        self.wsURL = UserDefaults.standard.string(forKey: "ws_url")
            ?? "wss://4928ba6f960f.ngrok-free.app/ws"
    }
}

