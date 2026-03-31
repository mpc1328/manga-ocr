import AVFoundation
import UIKit
import Combine

/// Manages the camera session and delivers sample buffers for OCR processing.
final class CameraManager: NSObject, ObservableObject {

    @Published var error: String?
    @Published var isRunning = false

    let session = AVCaptureSession()

    /// Called every time a new video frame is captured.
    var onFrame: ((CMSampleBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "com.mangaocr.camera")
    private let videoOutput = AVCaptureVideoDataOutput()

    // MARK: - Setup

    func configure() {
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080

        // Camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back) else {
            publish(error: "Fotocamera non disponibile")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(input) else {
                publish(error: "Impossibile aggiungere input fotocamera")
                return
            }
            session.addInput(input)
        } catch {
            publish(error: error.localizedDescription)
            return
        }

        // Video output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(videoOutput) else {
            publish(error: "Impossibile aggiungere output video")
            return
        }
        session.addOutput(videoOutput)

        // Set orientation to portrait
        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }

        session.commitConfiguration()
    }

    // MARK: - Start / Stop

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    private func publish(error message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.error = message
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        onFrame?(sampleBuffer)
    }
}
