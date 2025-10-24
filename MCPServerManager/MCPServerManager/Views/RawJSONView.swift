import SwiftUI

struct RawJSONView: View {
    @ObservedObject var viewModel: ServerViewModel
    @State private var jsonText: String = ""
    @State private var isDirty: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Info panel
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RAW JSON EDITOR")
                        .font(.scaled(.caption))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text("Edit the full configuration in JSON format. Changes will be applied to the active config.")
                        .font(.scaled(.caption))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isDirty {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("Unsaved edits")
                            .font(.scaled(.caption))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            .padding(20)

            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorMessage)
                }
                .font(.scaled(.subheadline))
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
                .padding(.horizontal, 20)
            }

            // Text editor
            TextEditor(text: $jsonText)
                .font(.scaled(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.3))
                .padding(20)
                .focusable(true)
                .onChange(of: jsonText) { newValue in
                    isDirty = newValue != serversToJSON()
                }

            // Action buttons
            HStack(spacing: 12) {
                Button("Format JSON") {
                    formatJSON()
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    jsonText = serversToJSON()
                    isDirty = false
                    errorMessage = ""
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Apply Changes") {
                    applyChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isDirty)
            }
            .padding(20)
        }
        .onAppear {
            jsonText = serversToJSON()
        }
        .onChange(of: viewModel.filterMode) { _ in
            if !isDirty {
                jsonText = serversToJSON()
            }
        }
        .onChange(of: viewModel.searchText) { _ in
            if !isDirty {
                jsonText = serversToJSON()
            }
        }
    }

    private func serversToJSON() -> String {
        // Use filteredServers to respect search and filter mode
        let filteredServers = viewModel.filteredServers
            .reduce(into: [String: ServerConfig]()) { result, server in
                result[server.name] = server.config
            }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(filteredServers),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }

    private func formatJSON() {
        guard let data = jsonText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: formatted, encoding: .utf8) else {
            errorMessage = "Invalid JSON format"
            return
        }
        jsonText = result
        errorMessage = ""
    }

    private func applyChanges() {
        do {
            guard let data = jsonText.data(using: .utf8) else {
                throw NSError(domain: "Invalid JSON", code: -1)
            }

            let serverDict = try JSONDecoder().decode([String: ServerConfig].self, from: data)
            let configIndex = viewModel.settings.activeConfigIndex

            // Remove all servers from this config
            for i in 0..<viewModel.servers.count {
                viewModel.servers[i].inConfigs[configIndex] = false
            }

            // Add/update servers from JSON
            for (name, config) in serverDict {
                if let index = viewModel.servers.firstIndex(where: { $0.name == name }) {
                    var updated = viewModel.servers[index]
                    updated.config = config
                    updated.inConfigs[configIndex] = true
                    updated.updatedAt = Date()
                    viewModel.servers[index] = updated
                } else {
                    var inConfigs = [false, false]
                    inConfigs[configIndex] = true

                    let newServer = ServerModel(
                        name: name,
                        config: config,
                        updatedAt: Date(),
                        inConfigs: inConfigs
                    )
                    viewModel.servers.append(newServer)
                }
            }

            viewModel.servers.sort { $0.name < $1.name }
            viewModel.objectWillChange.send()
            viewModel.syncToConfigs()

            isDirty = false
            errorMessage = ""
            viewModel.showToast = true
            viewModel.toastMessage = "Configuration updated"
            viewModel.toastType = .success
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
        }
    }
}
