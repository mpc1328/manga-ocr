import Foundation
import CoreGraphics

struct RecognizedTextBlock: Identifiable {
    let id = UUID()
    let text: String
    let translatedText: String?
    let boundingBox: CGRect // normalized coordinates (0-1)
    let confidence: Float
}
