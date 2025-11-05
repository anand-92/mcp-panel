import Foundation

/// Represents a remote control session for mobile device access
struct RemoteControlSession: Codable, Identifiable {
    let id: UUID
    let token: String
    let createdAt: Date
    let ipAddress: String
    let port: Int
    var isActive: Bool

    init(ipAddress: String, port: Int = 8765) {
        self.id = UUID()
        self.token = UUID().uuidString
        self.createdAt = Date()
        self.ipAddress = ipAddress
        self.port = port
        self.isActive = false
    }

    /// Returns the full URL that should be encoded in the QR code
    var url: String {
        "http://\(ipAddress):\(port)?token=\(token)"
    }

    /// Validates if a given token matches this session
    func validateToken(_ token: String) -> Bool {
        return self.token == token && isActive
    }
}

/// Settings related to remote control feature
struct RemoteControlSettings: Codable {
    var isEnabled: Bool
    var port: Int
    var currentSession: RemoteControlSession?

    static let `default` = RemoteControlSettings(
        isEnabled: false,
        port: 8765,
        currentSession: nil
    )

    init(isEnabled: Bool = false, port: Int = 8765, currentSession: RemoteControlSession? = nil) {
        self.isEnabled = isEnabled
        self.port = port
        self.currentSession = currentSession
    }
}
