import SwiftUI

struct AddServerModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ServerViewModel

    @State private var jsonText: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BULK ADD")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text("Add Servers")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SERVER JSON")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    Text("Paste server definitions in the format: {\"server-name\": {\"command\": \"...\"}} or just the config object")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $jsonText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 300)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button("Format JSON") {
                    formatJSON()
                }
                .buttonStyle(.bordered)

                Button("Validate") {
                    validateJSON()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Add Servers") {
                    addServers()
                }
                .buttonStyle(.borderedProminent)
                .disabled(jsonText.isEmpty)
            }
            .padding(24)
        }
        .frame(width: 600, height: 550)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 30)
        )
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

    private func validateJSON() {
        guard let data = jsonText.data(using: .utf8) else {
            errorMessage = "Invalid text encoding"
            return
        }

        do {
            _ = try JSONDecoder().decode([String: ServerConfig].self, from: data)
            errorMessage = ""
        } catch {
            errorMessage = "Validation failed: \(error.localizedDescription)"
        }
    }

    private func addServers() {
        viewModel.addServers(from: jsonText)
        isPresented = false
        jsonText = ""
        errorMessage = ""
    }
}
