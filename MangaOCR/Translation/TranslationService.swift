import Foundation

/// Translates English text to Italian using MyMemory free translation API.
@MainActor
final class TranslationService: ObservableObject {

    private let cache = NSCache<NSString, NSString>()

    init() {
        cache.countLimit = 2000
    }

    // MARK: - Public

    func translate(_ text: String) async -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        if let cached = cache.object(forKey: trimmed as NSString) {
            return cached as String
        }

        if let result = await callMyMemory(trimmed) {
            cache.setObject(result as NSString, forKey: trimmed as NSString)
            return result
        }

        return text
    }

    func translate(blocks: [RecognizedTextBlock]) async -> [RecognizedTextBlock] {
        var results = blocks
        for i in results.indices {
            let translated = await translate(results[i].text)
            let original = results[i]
            results[i] = RecognizedTextBlock(
                text: original.text,
                translatedText: translated,
                boundingBox: original.boundingBox,
                confidence: original.confidence
            )
        }
        return results
    }

    // MARK: - MyMemory API

    private func callMyMemory(_ text: String) async -> String? {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        let urlString = "https://api.mymemory.translated.net/get?q=\(encoded)&langpair=en|it"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["responseData"] as? [String: Any],
               let translated = responseData["translatedText"] as? String {
                return translated
            }
        } catch {
            print("[Translation] Error: \(error.localizedDescription)")
        }
        return nil
    }
}
