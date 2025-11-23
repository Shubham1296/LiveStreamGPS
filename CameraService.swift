//
// CameraService.swift
// LiveStreamGPS
//

import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject {

    @Published var previewImage: UIImage?
    @Published var fps: Int = 0

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let cameraQueue = DispatchQueue(label: "camera.frame.queue", qos: .userInitiated)
    private let ciContext = CIContext()

    private var lastFrameTime = Date()
    var isStreaming = false

    // set by ContentView before start
    weak var webSocket: WebSocketClient?
    weak var location: LocationService?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("CameraService: cannot create input")
            session.commitConfiguration()
            return
        }
        if session.canAddInput(input) { session.addInput(input) }

        // Output
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }

        // Set delegate after adding output
        output.setSampleBufferDelegate(self, queue: cameraQueue)

        session.commitConfiguration()
    }

    func start() {
        isStreaming = true
        // set orientation for connections
        setVideoOrientation(.landscapeRight)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        isStreaming = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func setVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        for connection in output.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
        }
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = (device.torchMode == .on) ? .off : .on
            device.unlockForConfiguration()
        } catch {
            print("Torch error:", error.localizedDescription)
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard isStreaming else { return }
        guard let loc = location else { return }

        let now = Date()
        // throttle to ~5 FPS (adjust as needed)
        let minInterval: TimeInterval = 0.20
        if now.timeIntervalSince(lastFrameTime) < minInterval { return }
        lastFrameTime = now

        // Extract pixel buffer for preview & JPEG
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Rotate for landscape-right if needed
        let rotated = ciImage.transformed(by: CGAffineTransform(rotationAngle: -.pi/2))

        guard let cgImage = ciContext.createCGImage(rotated, from: rotated.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)

        // update UI on main
        DispatchQueue.main.async { [weak self] in
            self?.previewImage = uiImage
        }

        // FPS calc
        // (This is simplified — you may want a moving average)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let fpsLocal = Int(1.0 / max(0.001, now.timeIntervalSince(self.lastFrameTime)))
            self.fps = fpsLocal
        }

        // Prepare JSON + base64 image and send as TEXT frame (MainActor)
        Task { @MainActor in
            guard let ws = webSocket, ws.isConnected else { return }

            guard let jpeg = uiImage.jpegData(compressionQuality: 0.5) else { return }
            let imageB64 = jpeg.base64EncodedString()

            let payload: [String: Any] = [
                "timestamp": ISO8601DateFormatter().string(from: now),
                "lat": loc.latitude,
                "lon": loc.longitude,
                "accuracy": loc.accuracy,
                "image": imageB64
            ]

            do {
                let data = try JSONSerialization.data(withJSONObject: payload, options: [])
                if let s = String(data: data, encoding: .utf8) {
                    ws.sendText(s)
                }
            } catch {
                print("CameraService: payload encode error:", error.localizedDescription)
            }
        }
    }
}
