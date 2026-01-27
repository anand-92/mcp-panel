import Foundation

/// Manages security-scoped bookmarks for persistent file access under App Sandbox
class BookmarkManager {
    static let shared = BookmarkManager()

    private init() {}

    // Use App Groups UserDefaults so widget can access bookmarks
    private let suiteName = "group.com.anand-92.mcp-panel"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static func bookmarkKey(for path: String) -> String {
            return "bookmark_\(path.replacingOccurrences(of: "~", with: "home"))"
        }
    }

    // MARK: - Bookmark Operations

    /// Stores a security-scoped bookmark for the given URL
    func storeBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        let key = Keys.bookmarkKey(for: url.path)

        // Store in both standard and shared defaults for migration
        UserDefaults.standard.set(bookmarkData, forKey: key)
        sharedDefaults?.set(bookmarkData, forKey: key)
        sharedDefaults?.synchronize()

        print("✅ Stored bookmark for: \(url.path)")
    }

    /// Resolves a bookmark for the given path and returns the URL
    /// Returns nil if no bookmark exists or resolution fails
    func resolveBookmark(for path: String) -> URL? {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let key = Keys.bookmarkKey(for: expandedPath)

        // Check shared defaults first (for widget access), then fall back to standard defaults
        var bookmarkData = sharedDefaults?.data(forKey: key)
        if bookmarkData == nil {
            bookmarkData = UserDefaults.standard.data(forKey: key)
            // Migrate to shared defaults if found in standard
            if let data = bookmarkData {
                sharedDefaults?.set(data, forKey: key)
                sharedDefaults?.synchronize()
            }
        }

        guard let bookmarkData = bookmarkData else {
            print("⚠️ No bookmark found for: \(path)")
            return nil
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                print("⚠️ Bookmark is stale for: \(path), attempting to refresh...")
                // Try to refresh the bookmark - but don't delete if refresh fails
                // The stale bookmark may still work for reading
                do {
                    // Need security-scoped access to create new bookmark
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    try storeBookmark(for: url)
                    print("✅ Refreshed stale bookmark for: \(path)")
                } catch {
                    // Don't delete - stale bookmarks often still work for reading
                    print("⚠️ Could not refresh bookmark for: \(path) - will retry on next file selection")
                }
            }

            print("✅ Resolved bookmark for: \(path)")
            return url

        } catch {
            print("❌ Failed to resolve bookmark for: \(path) - \(error.localizedDescription)")
            // Clear invalid bookmark
            UserDefaults.standard.removeObject(forKey: key)
            return nil
        }
    }

    /// Removes a stored bookmark for the given path
    func removeBookmark(for path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let key = Keys.bookmarkKey(for: expandedPath)
        UserDefaults.standard.removeObject(forKey: key)
        print("🗑️ Removed bookmark for: \(path)")
    }

    /// Checks if a bookmark exists for the given path
    func hasBookmark(for path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let key = Keys.bookmarkKey(for: expandedPath)
        return UserDefaults.standard.data(forKey: key) != nil
    }

    /// Clears all stored bookmarks
    func clearAllBookmarks() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        for key in allKeys where key.hasPrefix("bookmark_") {
            defaults.removeObject(forKey: key)
        }

        print("🗑️ Cleared all bookmarks")
    }
}

// MARK: - Security-Scoped Resource Helper

extension URL {
    /// Executes a closure with security-scoped access to this URL
    func withSecurityScopedAccess<T>(_ closure: (URL) throws -> T) throws -> T {
        let accessing = startAccessingSecurityScopedResource()
        defer {
            if accessing {
                stopAccessingSecurityScopedResource()
            }
        }
        return try closure(self)
    }
}
