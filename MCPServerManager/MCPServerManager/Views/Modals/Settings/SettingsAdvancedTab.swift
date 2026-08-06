import SwiftUI

/// Network options and the config connectivity test.
struct SettingsAdvancedTab: View {
    @ObservedObject var viewModel: ServerViewModel

    @Environment(\.themeColors) private var themeColors
    @State private var fetchServerLogos = true
    @State private var testingConnection = false
    @State private var testResult = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionCard(title: "Network", icon: "network") {
                VStack(alignment: .leading, spacing: 16) {
                    SettingsToggleRow(
                        isOn: $fetchServerLogos,
                        icon: "photo.circle.fill",
                        label: "Fetch server logos",
                        description: "Download logos from the internet (no tracking)"
                    )
                    .onChange(of: fetchServerLogos) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "fetchServerLogos")
                    }

                    Divider().opacity(0.3)

                    connectivityTest
                }
            }
        }
        .onAppear {
            fetchServerLogos = UserDefaults.standard.object(forKey: "fetchServerLogos") as? Bool ?? true
        }
    }

    private var connectivityTest: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connectivity")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundStyle(themeColors.mutedText)
                .textCase(.uppercase)
                .tracking(0.5)

            Button(action: testConnection) {
                HStack(spacing: 8) {
                    if testingConnection {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "network.badge.shield.half.filled")
                    }
                    Text(testingConnection ? "Testing..." : "Test Connection")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .disabled(testingConnection)

            if !testResult.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isError ? themeColors.errorColor : themeColors.successColor)
                        .font(.system(size: 12))

                    Text(testResult)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(themeColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var isError: Bool { testResult.hasPrefix("Error") }

    private func testConnection() {
        testingConnection = true
        testResult = ""

        Task {
            let result = await viewModel.testConnection(to: viewModel.settings.configPath)

            withAnimation(.easeInOut(duration: 0.2)) {
                testingConnection = false
                switch result {
                case .success(let count):
                    testResult = "Found \(count) server(s) in config"
                case .failure(let error):
                    testResult = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
