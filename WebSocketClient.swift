//
//  WebSocketClient.swift
//  LiveStreamGPS
//

import Foundation

class WebSocketClient: ObservableObject {
    private var socket: URLSessionWebSocketTask?
    @Published var isConnected: Bool = false
    @Published var logs: [String] = []

    init() {
        connect()
    }

    func connect() {
        let url = URL(string: "ws://192.168.1.22:8000/ws")!   // change your IP
        let config = URLSessionConfiguration.default

        socket = URLSession(configuration: config).webSocketTask(with: url)
        socket?.resume()

        isConnected = true
        log("WebSocket Connected")

        listen()
    }

    func disconnect() {
        socket?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
        log("WebSocket Disconnected")
    }

    private func log(_ m: String) {
        DispatchQueue.main.async {
            self.logs.append(m)
            if self.logs.count > 10 { self.logs.removeFirst() }
        }
    }

    func listen() {
        socket?.receive { result in
            switch result {
            case .success(_):
                self.log("Received server message")
            case .failure(let e):
                self.isConnected = false
                self.log("Receive error: \(e.localizedDescription)")
            }
            self.listen()
        }
    }

    func sendJSON(_ json: [String: Any]) {
        guard let socket = socket else { return }

        let data = try! JSONSerialization.data(withJSONObject: json)
        let msg = URLSessionWebSocketTask.Message.data(data)

        socket.send(msg) { error in
            if let err = error {
                self.log("Send error: \(err.localizedDescription)")
            } else {
                self.log("Frame + GPS Sent")
            }
        }
    }
}

