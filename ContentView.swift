import SwiftUI

struct ContentView: View {

    @StateObject var camera = CameraService()
    @StateObject var location = LocationService()
    @StateObject var ws = WebSocketClient()
    @StateObject var backup = BackupService.shared

    @State private var isStreaming = false
    @State private var showBackupFiles = false

    var body: some View {

        VStack(spacing: 18) {

            // MARK: - Server Indicator
            HStack {
                Circle()
                    .fill(ws.isConnected ? Color.green : Color.red)
                    .frame(width: 14, height: 14)

                Text(ws.isConnected ? "Server Connected" : "Server Offline")
                    .foregroundColor(.white)
                    .font(.caption)

                Spacer()
            }
            .padding(.horizontal)

            // MARK: - Camera Preview
            ZStack {
                CameraPreview(session: camera.session)
                    .frame(height: 260)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3))
                    )

                if !isStreaming {
                    Color.black.opacity(0.5).cornerRadius(16)
                    Text("Camera Paused")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .padding(.horizontal)

            // MARK: - GPS
            VStack(spacing: 6) {
                Text("Latitude: \(location.latitude)")
                Text("Longitude: \(location.longitude)")
            }
            .foregroundColor(.white)
            .font(.body)

            // MARK: - Streaming Button
            Button(action: { isStreaming.toggle() }) {
                Text(isStreaming ? "STOP STREAMING" : "START STREAMING")
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            // MARK: - Backup Viewer Button
            Button(action: {
                showBackupFiles.toggle()
            }) {
                Text("Show Backup Entries")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            // MARK: - Open Backup Folder
            Button(action: openBackupFolder) {
                Text("Open Backup Folder")
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            // MARK: - Logs
            VStack(alignment: .leading) {
                Text("Recent Logs")
                    .foregroundColor(.white)
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(ws.logs, id: \.self) { log in
                            Text(log)
                                .foregroundColor(.white.opacity(0.9))
                                .font(.caption)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .frame(height: 140)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

            }.padding(.horizontal)

            Spacer()

        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showBackupFiles) {
            BackupListView()
        }
        .onChange(of: camera.currentFrame) { newFrame in
            if isStreaming, let frame = newFrame {
                sendFrame(frame)
            }
        }
    }

    // MARK: - Save + Send
    func sendFrame(_ frame: Data) {
        let timestamp = ISO8601DateFormatter().string(from: Date())

        // Save backup
        BackupService.shared.saveFrame(
            frame: frame,
            lat: location.latitude,
            lon: location.longitude,
            timestamp: timestamp
        )

        // Send to server
        let payload: [String: Any] = [
            "timestamp": timestamp,
            "lat": location.latitude,
            "lon": location.longitude,
            "frame": frame.base64EncodedString()
        ]

        ws.sendJSON(payload)
    }

    // MARK: - Open backup folder
    func openBackupFolder() {
        let url = BackupService.shared.getBackupFolderURL()
        let controller = UIDocumentInteractionController(url: url)
        controller.presentPreview(animated: true)
    }
}

