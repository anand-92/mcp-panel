import Foundation
import AppKit

/// Manages custom icon storage in Application Support directory
/// Copies user-selected images to a sandboxed location for persistent access
class CustomIconManager {
    static let shared = CustomIconManager()

    private init() {
        // Ensure custom icons directory exists
        try? FileManager.default.createDirectory(at: customIconsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Directory Management

    /// Directory where custom icons are stored
    /// ~/Library/Application Support/MCPServerManager/CustomIcons/
    private var customIconsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport
            .appendingPathComponent("MCPServerManager", isDirectory: true)
            .appendingPathComponent("CustomIcons", isDirectory: true)
    }

    // MARK: - Validation Constants

    private let maxImageDimension: CGFloat = 2048
    private let maxFileSizeBytes: Int = 10 * 1024 * 1024 // 10MB

    // MARK: - Public Methods

    /// Validates and copies a user-selected image to the custom icons directory
    /// - Parameters:
    ///   - sourceURL: The URL of the user-selected image file
    ///   - serverName: The name of the server (used to generate unique filename)
    /// - Returns: The filename of the copied image (not full path)
    /// - Throws: Error if validation fails or copy fails
    func storeCustomIcon(from sourceURL: URL, for serverName: String) throws -> String {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw CustomIconError.fileNotFound
        }

        // Validate file size
        let attributes = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        guard fileSize <= maxFileSizeBytes else {
            throw CustomIconError.fileTooLarge(sizeInMB: Double(fileSize) / (1024 * 1024))
        }

        // Validate it's an image and check dimensions
        guard let image = NSImage(contentsOf: sourceURL) else {
            throw CustomIconError.invalidImageFormat
        }

        let size = image.size
        guard size.width <= maxImageDimension && size.height <= maxImageDimension else {
            throw CustomIconError.imageTooLarge(width: size.width, height: size.height)
        }

        // Generate unique filename using server name and original extension
        let fileExtension = sourceURL.pathExtension
        let sanitizedName = sanitizeServerName(serverName)
        let filename = "\(sanitizedName).\(fileExtension)"

        let destinationURL = customIconsDirectory.appendingPathComponent(filename)

        // Remove existing file if present
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        // Copy file to custom icons directory
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        #if DEBUG
        print("CustomIconManager: Stored icon for '\(serverName)' as '\(filename)'")
        #endif

        return filename
    }

    /// Loads a custom icon by filename
    /// - Parameter filename: The filename of the custom icon
    /// - Returns: NSImage if found and loadable, nil otherwise
    func loadCustomIcon(filename: String) -> NSImage? {
        let url = customIconsDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: url.path) else {
            #if DEBUG
            print("CustomIconManager: Icon file not found: \(filename)")
            #endif
            return nil
        }

        return NSImage(contentsOf: url)
    }

    /// Removes a custom icon file
    /// - Parameter filename: The filename of the custom icon to remove
    func removeCustomIcon(filename: String) {
        let url = customIconsDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
            #if DEBUG
            print("CustomIconManager: Removed icon: \(filename)")
            #endif
        } catch {
            #if DEBUG
            print("CustomIconManager: Failed to remove icon \(filename): \(error)")
            #endif
        }
    }

    /// Removes all unused custom icons (icons not referenced by any server)
    /// - Parameter usedFilenames: Set of filenames currently in use
    func cleanupUnusedIcons(usedFilenames: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: customIconsDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        var removedCount = 0
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            if !usedFilenames.contains(filename) {
                removeCustomIcon(filename: filename)
                removedCount += 1
            }
        }

        #if DEBUG
        if removedCount > 0 {
            print("CustomIconManager: Cleaned up \(removedCount) unused icon(s)")
        }
        #endif
    }

    // MARK: - Private Helpers

    /// Sanitizes server name for use as filename
    private func sanitizeServerName(_ name: String) -> String {
        // Replace unsafe characters with underscores
        let unsafe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted
        let sanitized = name.components(separatedBy: unsafe).joined(separator: "_")

        // Truncate to reasonable length (max 100 chars)
        let maxLength = 100
        if sanitized.count > maxLength {
            let index = sanitized.index(sanitized.startIndex, offsetBy: maxLength)
            return String(sanitized[..<index])
        }

        return sanitized
    }
}

// MARK: - Custom Icon Errors

enum CustomIconError: LocalizedError {
    case fileNotFound
    case fileTooLarge(sizeInMB: Double)
    case imageTooLarge(width: CGFloat, height: CGFloat)
    case invalidImageFormat
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Selected file could not be found"
        case .fileTooLarge(let sizeMB):
            return String(format: "Image file is too large (%.1f MB). Maximum size is 10 MB.", sizeMB)
        case .imageTooLarge(let width, let height):
            return String(format: "Image dimensions too large (%.0f × %.0f). Maximum is 2048 × 2048 pixels.", width, height)
        case .invalidImageFormat:
            return "Selected file is not a valid image format"
        case .copyFailed:
            return "Failed to save custom icon"
        }
    }
}
