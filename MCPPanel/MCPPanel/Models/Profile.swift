//
//  Profile.swift
//  MCP Panel
//

import Foundation

// MARK: - Profile Model

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var servers: [String: ServerConfig]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, servers: [String: ServerConfig] = [:]) {
        self.id = id
        self.name = name
        self.servers = servers
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var serverCount: Int {
        return servers.count
    }

    var enabledServerCount: Int {
        return servers.values.filter { $0.isEnabled }.count
    }

    mutating func updateTimestamp() {
        self.updatedAt = Date()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Profile File Structure

struct ProfileFile: Codable {
    var name: String
    var mcpServers: [String: ServerConfig]
    var createdAt: Date?
    var updatedAt: Date?

    init(name: String, servers: [String: ServerConfig]) {
        self.name = name
        self.mcpServers = servers
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    init(from profile: Profile) {
        self.name = profile.name
        self.mcpServers = profile.servers
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }

    func toProfile(id: UUID) -> Profile {
        return Profile(
            id: id,
            name: name,
            servers: mcpServers
        )
    }
}

// MARK: - Sample Data

extension Profile {
    static let sample = Profile(
        name: "Development",
        servers: [
            "filesystem": ServerConfig.samples[0],
            "github": ServerConfig.samples[1]
        ]
    )

    static let samples = [
        Profile(
            name: "Development",
            servers: [
                "filesystem": ServerConfig.samples[0]
            ]
        ),
        Profile(
            name: "Production",
            servers: [
                "github": ServerConfig.samples[1],
                "postgres": ServerConfig.samples[2]
            ]
        )
    ]
}
