import Vision
import CoreMedia
import UIKit

/// Performs OCR on camera frames using Apple Vision framework.
final class OCRProcessor {

    /// Minimum confidence threshold to accept a recognized text observation.
    var minimumConfidence: Float = 0.5

    /// Recognition languages (English for manga translated to English).
    var recognitionLanguages: [String] = ["en-US"]

    /// Process a sample buffer and return recognized text blocks.
    func recognizeText(in sampleBuffer: CMSampleBuffer) async -> [RecognizedTextBlock] {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks = observations.compactMap { observation -> RecognizedTextBlock? in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence >= self.minimumConfidence else {
                        return nil
                    }

                    // Vision returns bounding box in normalized coordinates with origin at bottom-left.
                    // Convert to top-left origin for UIKit/SwiftUI.
                    let box = observation.boundingBox
                    let flippedBox = CGRect(
                        x: box.origin.x,
                        y: 1 - box.origin.y - box.height,
                        width: box.width,
                        height: box.height
                    )

                    return RecognizedTextBlock(
                        text: candidate.string,
                        translatedText: nil,
                        boundingBox: flippedBox,
                        confidence: candidate.confidence
                    )
                }

                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = self.recognitionLanguages
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
