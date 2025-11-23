//
// ContentView.swift
// LiveStreamGPS
//

import SwiftUI

struct ContentView: View {

    @StateObject private var camera = CameraService()
    @StateObject private var location = LocationService()
    @StateObject private var ws = WebSocketClient()
    @ObservedObject private var server = ServerConfig.shared

    @State private var isRecording = false
    @State private var showLogs = false
    @State private var showEditURL = false

    var body: some View {
        ZStack {
            // Fullscreen camera preview (cover)
            GeometryReader { geo in
                if let img = camera.previewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Color.black
                    Text("Waiting for camera…")
                        .foregroundColor(.white)
                        .font(.headline)
                        .position(x: geo.size.width/2, y: geo.size.height/2)
                }
            }
            .ignoresSafeArea()
            // Top status bar (left)
            VStack {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("GPS ±\(String(format: "%.1f", location.accuracy)) m")
                        Divider().frame(height: 16)
                        Text("FPS \(camera.fps)")
                        Divider().frame(height: 16)
                        Circle()
                            .fill(ws.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(8)

                    Spacer()

                    Button(action: { showEditURL = true }) {
                        Image(systemName: "link")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }

                    Button(action: { showLogs.toggle() }) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 14)

                Spacer()
            }

            // Right floating buttons
            VStack {
                Spacer()
                VStack(spacing: 26) {
                    // Menu (empty)
                    CircleIconButton(systemName: "line.3.horizontal") {
                        // empty for now
                    }

                    // Record button
                    CircleIconButton(systemName: isRecording ? "stop.fill" : "record.circle.fill",
                                     fillColor: isRecording ? Color.red : Color.green) {
                        toggleRecording()
                    }
                }
                .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 80)

            // Logs drawer
            if showLogs {
                VStack {
                    Spacer()
                    LogsView(logs: ws.logs, onClose: { showLogs = false })
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            camera.webSocket = ws
            camera.location = location
            location.start()
        }
        .sheet(isPresented: $showEditURL) {
            EditURLView(isPresented: $showEditURL)
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
    }

    private func toggleRecording() {
        if isRecording {
            camera.stop()
            ws.disconnect()
        } else {
            ws.connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                camera.start()
            }
        }
        isRecording.toggle()
    }
}

// Reusable round button
struct CircleIconButton: View {
    var systemName: String
    var fillColor: Color = Color.white.opacity(0.15)
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(fillColor)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

// Edit URL sheet
struct EditURLView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var server = ServerConfig.shared
    @State private var tempURL: String = ""

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._tempURL = State(initialValue: ServerConfig.shared.wsURL)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("WebSocket Server URL")
                    .font(.headline)
                TextField("wss://your-ngrok-url/ws", text: $tempURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Spacer()

                Button("Save & Close") {
                    server.wsURL = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    // notify UI (optional)
                    NotificationCenter.default.post(name: NSNotification.Name("ServerURLChanged"), object: nil)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
}

// Logs view
struct LogsView: View {
    var logs: [String]
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Logs").foregroundColor(.white).font(.headline)
                Spacer()
                Button("Close", action: onClose)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.7))

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(logs.indices, id: \.self) { i in
                        Text(logs[i])
                            .font(.caption2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            .frame(height: 300)
            .background(Color.black.opacity(0.5))
        }
        .background(Color.black.opacity(0.3))
        .ignoresSafeArea(edges: .bottom)
    }
}
