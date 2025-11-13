//
//  CameraService.swift
//  LiveStreamGPS
//

import Foundation
import AVFoundation
import UIKit

class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {

    // Public session for SwiftUI
    let session = AVCaptureSession()

    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.queue")
    private var lastFrameTime = Date()

    @Published var currentFrame: Data?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .medium

        // Camera input
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("Camera input error")
            return
        }

        if session.canAddInput(input) { session.addInput(input) }

        // Camera output
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()
        session.startRunning()
    }

    // Capture frame
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = Date()
        if now.timeIntervalSince(lastFrameTime) < 0.5 { return } // 2 FPS
        lastFrameTime = now

        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImg = CIImage(cvPixelBuffer: buffer)
        let ctx = CIContext()

        if let cgImg = ctx.createCGImage(ciImg, from: ciImg.extent) {
            let uiImage = UIImage(cgImage: cgImg)
            if let jpeg = uiImage.jpegData(compressionQuality: 0.5) {
                DispatchQueue.main.async { self.currentFrame = jpeg }
            }
        }
    }
}

