import SwiftUI
import AVFoundation

@MainActor
final class MangaOCRViewModel: ObservableObject {

    @Published var textBlocks: [RecognizedTextBlock] = []
    @Published var isProcessing = false
    @Published var isPaused = false
    @Published var errorMessage: String?

    let cameraManager = CameraManager()
    let translationService = TranslationService()

    private let ocrProcessor = OCRProcessor()
    private var isOCRBusy = false
    var scanInterval: TimeInterval = 0.5
    private var lastScanTime: Date = .distantPast

    func startCamera() {
        cameraManager.configure()
        cameraManager.onFrame = { [weak self] buffer in
            guard let self else { return }
            Task { @MainActor in
                await self.handleFrame(buffer)
            }
        }
        cameraManager.start()
    }

    func stopCamera() {
        cameraManager.stop()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            cameraManager.stop()
        } else {
            textBlocks = []
            cameraManager.start()
        }
    }

    private func handleFrame(_ buffer: CMSampleBuffer) async {
        guard !isPaused, !isOCRBusy else { return }

        let now = Date()
        guard now.timeIntervalSince(lastScanTime) >= scanInterval else { return }

        isOCRBusy = true
        isProcessing = true
        lastScanTime = now

        let recognized = await ocrProcessor.recognizeText(in: buffer)

        if recognized.isEmpty {
            isProcessing = false
            isOCRBusy = false
            return
        }

        let translated = await translationService.translate(blocks: recognized)
        textBlocks = translated
        isProcessing = false
        isOCRBusy = false
    }
}
