import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showAddServer: Bool
    @State private var showImporter = false
    @State private var showExporter = false

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("QUICK ACTIONS")
                    .font(.scaled(.caption))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                // Explore New MCPs
                Button(action: openRegistry) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Explore New MCPs")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.scaled(.caption))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                    )
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Divider()

                // New Server
                Button(action: { showAddServer = true }) {
                    Label("New Server", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)

                // Import JSON
                Button(action: { showImporter = true }) {
                    Label("Import JSON", systemImage: "arrow.down.doc.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                // Export JSON
                Button(action: { showExporter = true }) {
                    Label("Export JSON", systemImage: "arrow.up.doc.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(width: 240)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            onCompletion: handleImport
        )
        .fileExporter(
            isPresented: $showExporter,
            document: JSONDocument(content: viewModel.exportServers()),
            contentType: .json,
            defaultFilename: "mcp-servers.json"
        ) { result in
            if case .success = result {
                // Success
            }
        }
    }

    private func openRegistry() {
        if let url = URL(string: AppConstants.mcpRegistryURL) {
            NSWorkspace.shared.open(url)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Imported JSON length: \(jsonString.count) characters")
                    viewModel.addServers(from: jsonString)
                } else {
                    print("ERROR: Could not convert data to string")
                }
            } catch {
                print("ERROR: Import error: \(error)")
            }
        case .failure(let error):
            print("ERROR: File picker error: \(error)")
        }
    }
}

// MARK: - JSON Document for Export

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            content = string
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = content.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
