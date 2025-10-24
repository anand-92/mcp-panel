//
//  RawJsonView.swift
//  MCP Panel
//

import SwiftUI

struct RawJsonView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Raw JSON Editor")
                    .font(.headline)

                Spacer()

                if appState.isEditingRawJson {
                    Button("Cancel") {
                        appState.isEditingRawJson = false
                        appState.updateRawJsonText()
                    }

                    Button("Save") {
                        Task {
                            await appState.saveRawJson()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Edit") {
                        appState.isEditingRawJson = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            // JSON editor
            if appState.isEditingRawJson {
                TextEditor(text: $appState.rawJsonText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
            } else {
                ScrollView {
                    Text(appState.rawJsonText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }
}

#Preview {
    RawJsonView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
