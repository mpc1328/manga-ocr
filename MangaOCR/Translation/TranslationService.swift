import Foundation
#if canImport(Translation)
import Translation
#endif

/// Translates text from English to Italian using Apple's on-device Translation framework (iOS 18+).
/// Falls back to MyMemory free API if Translation framework is unavailable.
@MainActor
final class TranslationService: ObservableObject {

    @Published var isReady = false

    private let cache = NSCache<NSString, NSString>()

    init() {
        cache.countLimit = 2000
    }

    // MARK: - Translation

    /// Translate a single string from English to Italian.
    func translate(_ text: String) async -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        // Check cache first
        if let cached = cache.object(forKey: trimmed as NSString) {
            return cached as String
        }

        // Try Apple Translation framework (iOS 18+)
        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            if let result = await translateWithApple(trimmed) {
                cache.setObject(result as NSString, forKey: trimmed as NSString)
                return result
            }
        }
        #endif

        // Fallback: MyMemory free translation API
        if let result = await translateWithMyMemory(trimmed) {
            cache.setObject(result as NSString, forKey: trimmed as NSString)
            return result
        }

        return text
    }

    /// Translate an array of text blocks, returning blocks with translatedText filled in.
    func translate(blocks: [RecognizedTextBlock]) async -> [RecognizedTextBlock] {
        await withTaskGroup(of: (Int, String).self) { group in
            for (index, block) in blocks.enumerated() {
                group.addTask {
                    let translated = await self.translate(block.text)
                    return (index, translated)
                }
            }

            var results = blocks
            for await (index, translated) in group {
                let original = results[index]
                results[index] = RecognizedTextBlock(
                    text: original.text,
                    translatedText: translated,
                    boundingBox: original.boundingBox,
                    confidence: original.confidence
                )
            }
            return results
        }
    }

    // MARK: - Apple Translation Framework

    #if canImport(Translation)
    @available(iOS 18.0, *)
    private func translateWithApple(_ text: String) async -> String? {
        do {
            let session = TranslationSession(configuration: .init(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "it")
            ))

            let response = try await session.translate(text)
            return response.targetText
        } catch {
            print("[TranslationService] Apple Translation error: \(error)")
            return nil
        }
    }
    #endif

    // MARK: - MyMemory API Fallback

    private func translateWithMyMemory(_ text: String) async -> String? {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.mymemory.translated.net/get?q=\(encoded)&langpair=en|it") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let responseData = json?["responseData"] as? [String: Any]
            return responseData?["translatedText"] as? String
        } catch {
            print("[TranslationService] MyMemory API error: \(error)")
            return nil
        }
    }
}
