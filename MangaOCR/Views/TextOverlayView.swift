import SwiftUI

/// Draws translated text overlay boxes on top of the camera preview.
struct TextOverlayView: View {

    let blocks: [RecognizedTextBlock]
    let viewSize: CGSize

    var body: some View {
        ZStack {
            ForEach(blocks) { block in
                let rect = absoluteRect(for: block.boundingBox, in: viewSize)

                ZStack {
                    // Semi-transparent background to cover original text
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.80))

                    // Translated text
                    Text(block.translatedText ?? block.text)
                        .font(.system(size: fontSize(for: rect), weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                        .lineLimit(4)
                        .padding(3)
                }
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            }
        }
    }

    // Convert normalized (0-1) bounding box to screen coordinates.
    private func absoluteRect(for normalized: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: normalized.origin.x * size.width,
            y: normalized.origin.y * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }

    // Dynamic font size based on the height of the bounding box.
    private func fontSize(for rect: CGRect) -> CGFloat {
        let size = max(rect.height * 0.55, 10)
        return min(size, 32)
    }
}
