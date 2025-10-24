import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: ServerViewModel

    var body: some View {
        HStack(spacing: 16) {
            // View mode toggle
            Picker("View", selection: $viewModel.viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            // Filter dropdown
            Picker("Filter", selection: $viewModel.filterMode) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .frame(width: 180)

            Spacer()

            // Toggle all servers
            Button(action: {
                let allEnabled = viewModel.servers.allSatisfy {
                    $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false
                }
                print("DEBUG: Toggle All clicked, currently allEnabled: \(allEnabled), will set to: \(!allEnabled)")
                viewModel.toggleAllServers(!allEnabled)
            }) {
                let allEnabled = viewModel.servers.allSatisfy {
                    $0.inConfigs[safe: viewModel.settings.activeConfigIndex] ?? false
                }
                HStack(spacing: 8) {
                    Text(allEnabled ? "Disable All" : "Enable All")
                        .font(.subheadline)

                    // Visual indicator only - the button wrapper handles the action
                    ZStack {
                        Capsule()
                            .fill(allEnabled ? AnyShapeStyle(LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.gray.opacity(0.3)))
                            .frame(width: 44, height: 24)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .offset(x: allEnabled ? 10 : -10)
                    }
                }
            }
            .buttonStyle(.plain)

            // Save button
            Button(action: { viewModel.syncToConfigs() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.02))
    }
}
