import SwiftUI
import AVFoundation
import Combine

/// Main view model that orchestrates camera, OCR, and translation.
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
    private var cancellables = Set<AnyCancellable>()

    /// Interval between OCR scans in seconds.
    var scanInterval: TimeInterval = 0.4

    private var lastScanTime: Date = .distantPast

    init() {
        cameraManager.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in self?.errorMessage = msg }
            .store(in: &cancellables)
    }

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

    // MARK: - Frame Processing

    private func handleFrame(_ buffer: CMSampleBuffer) async {
        guard !isPaused, !isOCRBusy else { return }

        let now = Date()
        guard now.timeIntervalSince(lastScanTime) >= scanInterval else { return }

        isOCRBusy = true
        isProcessing = true
        lastScanTime = now

        // 1. OCR recognition
        let recognized = await ocrProcessor.recognizeText(in: buffer)

        guard !recognized.isEmpty else {
            isProcessing = false
            isOCRBusy = false
            return
        }

        // 2. Translate all blocks
        let translated = await translationService.translate(blocks: recognized)

        // 3. Update UI
        textBlocks = translated
        isProcessing = false
        isOCRBusy = false
    }
}
