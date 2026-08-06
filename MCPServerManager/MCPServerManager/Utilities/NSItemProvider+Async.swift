import Foundation
import UniformTypeIdentifiers

/// Async wrappers around `NSItemProvider`'s completion-handler API.
///
/// `NSItemProvider` is not `Sendable`, so the whole loader stays pinned to the
/// main actor: the provider never leaves the actor that received the drop, and
/// the load callbacks (which fire on an arbitrary queue) only resume a
/// continuation with a value type.
@MainActor
enum DroppedItemLoader {
    /// Resolve a dropped file URL and read its contents as UTF-8 text.
    static func readFile(from provider: NSItemProvider) async -> String? {
        guard let url = await fileURL(from: provider) else { return nil }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Read dropped text, preferring a raw plain-text data representation
    /// (reliable across drag sources) and falling back to a coerced string.
    static func readText(from provider: NSItemProvider) async -> String? {
        if let text = await plainText(from: provider) {
            return text
        }
        return await stringObject(from: provider)
    }

    // MARK: - Provider Primitives

    private static func fileURL(from provider: NSItemProvider) async -> URL? {
        let identifier = UTType.fileURL.identifier
        guard provider.hasItemConformingToTypeIdentifier(identifier) else { return nil }

        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: identifier, options: nil) { item, _ in
                // Decode inline: the callback runs off the main actor and
                // `NSSecureCoding` can't be sent across the boundary.
                let url: URL? = {
                    if let data = item as? Data {
                        return URL(dataRepresentation: data, relativeTo: nil)
                    }
                    if let url = item as? URL {
                        return url
                    }
                    if let string = item as? String {
                        return URL(string: string)
                    }
                    return nil
                }()
                continuation.resume(returning: url)
            }
        }
    }

    private static func plainText(from provider: NSItemProvider) async -> String? {
        let plainTextType = provider.registeredTypeIdentifiers.first {
            UTType($0)?.conforms(to: .plainText) == true
        }
        guard let plainTextType else { return nil }

        return await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: plainTextType) { data, _ in
                continuation.resume(returning: data.flatMap { String(data: $0, encoding: .utf8) })
            }
        }
    }

    private static func stringObject(from provider: NSItemProvider) async -> String? {
        guard provider.canLoadObject(ofClass: NSString.self) else { return nil }

        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                continuation.resume(returning: object as? String)
            }
        }
    }
}
