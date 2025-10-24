//
//  SearchService.swift
//  MCP Panel
//

import Foundation

class SearchService {

    // MARK: - Search

    func search(query: String, in servers: [ServerConfig], fuzzy: Bool = true) -> [ServerConfig] {
        guard !query.isEmpty else { return servers }

        let lowercaseQuery = query.lowercased()

        if fuzzy {
            return fuzzySearch(query: lowercaseQuery, in: servers)
        } else {
            return exactSearch(query: lowercaseQuery, in: servers)
        }
    }

    // MARK: - Exact Search

    private func exactSearch(query: String, in servers: [ServerConfig]) -> [ServerConfig] {
        return servers.filter { server in
            return matches(server: server, query: query)
        }
    }

    private func matches(server: ServerConfig, query: String) -> Bool {
        // Search in ID
        if server.id.lowercased().contains(query) {
            return true
        }

        // Search in command
        if server.command.lowercased().contains(query) {
            return true
        }

        // Search in args
        if let args = server.args {
            for arg in args {
                if arg.lowercased().contains(query) {
                    return true
                }
            }
        }

        // Search in env keys and values
        if let env = server.env {
            for (key, value) in env {
                if key.lowercased().contains(query) || value.lowercased().contains(query) {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Fuzzy Search

    private func fuzzySearch(query: String, in servers: [ServerConfig]) -> [ServerConfig] {
        var scoredServers: [(server: ServerConfig, score: Double)] = []

        for server in servers {
            let score = calculateFuzzyScore(server: server, query: query)
            if score > 0 {
                scoredServers.append((server, score))
            }
        }

        // Sort by score (higher is better)
        scoredServers.sort { $0.score > $1.score }

        return scoredServers.map { $0.server }
    }

    private func calculateFuzzyScore(server: ServerConfig, query: String) -> Double {
        var totalScore: Double = 0

        // Score ID (highest weight)
        let idScore = fuzzyMatch(query: query, text: server.id.lowercased()) * 10.0
        totalScore += idScore

        // Score command (medium weight)
        let commandScore = fuzzyMatch(query: query, text: server.command.lowercased()) * 5.0
        totalScore += commandScore

        // Score args (lower weight)
        if let args = server.args {
            for arg in args {
                let argScore = fuzzyMatch(query: query, text: arg.lowercased()) * 2.0
                totalScore += argScore
            }
        }

        // Score env (lower weight)
        if let env = server.env {
            for (key, value) in env {
                let keyScore = fuzzyMatch(query: query, text: key.lowercased()) * 1.5
                let valueScore = fuzzyMatch(query: query, text: value.lowercased()) * 1.0
                totalScore += keyScore + valueScore
            }
        }

        return totalScore
    }

    // MARK: - Fuzzy Matching Algorithm

    private func fuzzyMatch(query: String, text: String) -> Double {
        guard !query.isEmpty, !text.isEmpty else { return 0 }

        // Exact match gets highest score
        if text == query {
            return 100.0
        }

        // Starts with query gets high score
        if text.hasPrefix(query) {
            return 75.0
        }

        // Contains query gets medium score
        if text.contains(query) {
            return 50.0
        }

        // Calculate Levenshtein distance for fuzzy matching
        let distance = levenshteinDistance(query, text)
        let maxLength = max(query.count, text.count)

        // Convert distance to similarity score (0-1)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))

        // Only return positive scores for reasonable matches
        if similarity > 0.3 {
            return similarity * 25.0 // Scale to 0-25 range
        }

        return 0
    }

    // MARK: - Levenshtein Distance

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)

        var dist = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            dist[i][0] = i
        }

        for j in 0...s2.count {
            dist[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1

                dist[i][j] = min(
                    dist[i - 1][j] + 1,      // deletion
                    dist[i][j - 1] + 1,      // insertion
                    dist[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return dist[s1.count][s2.count]
    }

    // MARK: - Search Suggestions

    func getSearchSuggestions(from servers: [ServerConfig]) -> [String] {
        var suggestions: Set<String> = []

        for server in servers {
            // Add server IDs
            suggestions.insert(server.id)

            // Add command names (extract executable name)
            if let commandName = extractCommandName(from: server.command) {
                suggestions.insert(commandName)
            }

            // Add env keys
            if let env = server.env {
                for key in env.keys {
                    suggestions.insert(key)
                }
            }
        }

        return Array(suggestions).sorted()
    }

    private func extractCommandName(from command: String) -> String? {
        // Extract executable name from path or command
        let components = command.components(separatedBy: "/")
        if let last = components.last, !last.isEmpty {
            return last
        }

        return nil
    }
}
