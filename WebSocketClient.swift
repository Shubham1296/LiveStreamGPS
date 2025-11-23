//
// WebSocketClient.swift
// LiveStreamGPS
//

import Foundation

@MainActor
final class WebSocketClient: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var logs: [String] = []
    @Published var lastError: String = ""

    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 8

    init() {}

    func connect() {
        let urlString = ServerConfig.shared.wsURL.trimmingCharacters(in: .whitespacesAndNewlines)
        appendLog("Connecting → \(urlString)")

        guard let url = URL(string: urlString) else {
            lastError = "Invalid WS URL"
            appendLog("Invalid WS URL: \(urlString)")
            return
        }

        let conf = URLSessionConfiguration.default
        conf.waitsForConnectivity = true
        session = URLSession(configuration: conf)
        socket = session?.webSocketTask(with: url)
        socket?.resume()

        isConnected = true
        reconnectAttempts = 0
        listen()
        pingLoop()
    }

    func disconnect() {
        appendLog("Disconnecting")
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        socket?.cancel(with: .normalClosure, reason: nil)
        session?.invalidateAndCancel()
        session = nil
        socket = nil
        isConnected = false
    }

    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            appendLog("Max reconnect attempts reached")
            return
        }
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 60)
        appendLog("Reconnect in \(Int(delay))s (attempt \(reconnectAttempts))")
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.appendLog("Reconnecting (attempt \(self.reconnectAttempts))")
                self.connect()
            }
        }
    }

    private func listen() {
        socket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.appendLog("Recv text (\(text.count) chars)")
                    case .data(let data):
                        self.appendLog("Recv data (\(data.count) bytes)")
                    @unknown default:
                        self.appendLog("Recv unknown")
                    }
                case .failure(let error):
                    self.appendLog("WS receive error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.scheduleReconnect()
                    return
                }
                // continue listening
                self.listen()
            }
        }
    }

    private func pingLoop() {
        socket?.sendPing { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                if let e = error {
                    self.appendLog("Ping error: \(e.localizedDescription)")
                    self.isConnected = false
                    self.scheduleReconnect()
                    return
                }
                // schedule next ping
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                    self.pingLoop()
                }
            }
        }
    }

    func send(data: Data) {
        guard isConnected else {
            appendLog("Send skipped (not connected)")
            return
        }
        socket?.send(.data(data)) { [weak self] error in
            Task { @MainActor in
                if let e = error {
                    self?.appendLog("Send error: \(e.localizedDescription)")
                    self?.lastError = e.localizedDescription
                } else {
                    self?.appendLog("Sent \(data.count) bytes")
                }
            }
        }
    }

    func sendText(_ text: String) {
        guard isConnected else {
            appendLog("Skip text send (not connected)")
            return
        }
        socket?.send(.string(text)) { [weak self] error in
            Task { @MainActor in
                if let e = error {
                    self?.appendLog("Text send error: \(e.localizedDescription)")
                } else {
                    self?.appendLog("Sent text (\(text.count) chars)")
                }
            }
        }
    }

    // MARK: Logs (main actor)
    @MainActor
    func appendLog(_ text: String) {
        let entry = "[\(Self.ts())] \(text)"
        logs.insert(entry, at: 0)
        if logs.count > 300 { logs.removeLast() }
    }

    private static func ts() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }
}
