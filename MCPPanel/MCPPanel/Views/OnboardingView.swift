//
//  OnboardingView.swift
//  MCP Panel
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                FeaturesPage()
                    .tag(1)

                SetupPage()
                    .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Divider()

            // Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                } else {
                    Button("Skip") {
                        finishOnboarding()
                    }
                }

                Spacer()

                if currentPage < 2 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        finishOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    private func finishOnboarding() {
        appState.dismissOnboarding()
        dismiss()
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Welcome to MCP Panel")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Native macOS Manager for Claude MCP Servers")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(40)
    }
}

struct FeaturesPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Key Features")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "gear",
                    title: "Easy Server Management",
                    description: "Add, edit, and remove MCP servers with a simple interface"
                )

                FeatureRow(
                    icon: "magnifyingglass",
                    title: "Powerful Search",
                    description: "Find servers quickly with fuzzy search across all fields"
                )

                FeatureRow(
                    icon: "square.grid.2x2",
                    title: "Multiple View Modes",
                    description: "Switch between grid, list, and raw JSON views"
                )

                FeatureRow(
                    icon: "folder",
                    title: "Profile Support",
                    description: "Save and load different server configurations"
                )

                FeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Auto-sync",
                    description: "Changes sync automatically with Claude desktop app"
                )
            }

            Spacer()
        }
        .padding(40)
    }
}

struct SetupPage: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Quick Setup")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                SetupStep(
                    number: 1,
                    title: "Config File Location",
                    description: "MCP Panel uses your Claude config at:"
                )

                Text(appState.settings.configPath)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                SetupStep(
                    number: 2,
                    title: "Start Managing",
                    description: "Click 'Get Started' to begin managing your MCP servers!"
                )

                Text("You can change the config path anytime in Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(40)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 30, height: 30)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
