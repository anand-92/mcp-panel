import SwiftUI

/// Key/value editor for a server's `env` map and HTTP `headers`, so secrets can be
/// edited without hand-writing JSON. Values are masked until revealed.
struct InspectorEnvironmentTab: View {
    let server: ServerModel
    @Binding var draft: EnvironmentDraft
    let onSave: () -> Void
    let onRevert: () -> Void

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InspectorKeyValueSection(
                        title: "Environment Variables",
                        addLabel: "Add variable",
                        entries: $draft.env
                    )

                    Divider().opacity(0.3)

                    InspectorKeyValueSection(
                        title: "Headers",
                        addLabel: "Add header",
                        entries: $draft.headers
                    )
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                if draft.isDirty {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(themeColors.warningColor)
                            .frame(width: 7, height: 7)
                        Text("Unsaved edits")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(themeColors.warningColor)
                    }
                }

                Spacer()

                EditorButton(
                    title: "Revert",
                    style: .secondary,
                    themeColors: themeColors,
                    isEnabled: draft.isDirty,
                    action: onRevert
                )

                EditorButton(
                    title: "Save",
                    icon: "checkmark",
                    style: .primary,
                    themeColors: themeColors,
                    isEnabled: draft.isDirty,
                    action: onSave
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Draft Model

/// Editable snapshot of a server's `env` and `headers`, kept as ordered arrays so
/// rows stay put while typing (a dictionary would reorder on every keystroke).
struct EnvironmentDraft: Equatable {
    var env: [KeyValueEntry] = []
    var headers: [KeyValueEntry] = []
    private var original: Snapshot = Snapshot()

    private struct Snapshot: Equatable {
        var env: [KeyValueEntry] = []
        var headers: [KeyValueEntry] = []
    }

    init() {}

    init(config: ServerConfig) {
        env = Self.entries(from: config.env)
        headers = Self.entries(from: config.headers)
        original = Snapshot(env: env, headers: headers)
    }

    var isDirty: Bool {
        env != original.env || headers != original.headers
    }

    /// Apply the draft onto a copy of `config`, dropping rows with a blank key.
    /// An emptied section becomes `nil` rather than `[:]` so the written JSON stays clean.
    func applied(to config: ServerConfig) -> ServerConfig {
        var updated = config
        updated.env = Self.dictionary(from: env)
        updated.headers = Self.dictionary(from: headers)
        return updated
    }

    private static func entries(from dictionary: [String: String]?) -> [KeyValueEntry] {
        guard let dictionary = dictionary else { return [] }
        return dictionary
            .sorted { $0.key < $1.key }
            .map { KeyValueEntry(key: $0.key, value: $0.value) }
    }

    private static func dictionary(from entries: [KeyValueEntry]) -> [String: String]? {
        var result: [String: String] = [:]
        for entry in entries {
            let key = entry.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            result[key] = entry.value
        }
        return result.isEmpty ? nil : result
    }
}

struct KeyValueEntry: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
    var isRevealed: Bool = false

    static func == (lhs: KeyValueEntry, rhs: KeyValueEntry) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value
    }
}

// MARK: - Section

private struct InspectorKeyValueSection: View {
    let title: String
    let addLabel: String
    @Binding var entries: [KeyValueEntry]

    @Environment(\.themeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                InspectorSectionLabel(text: title)
                Spacer()
                Button {
                    entries.append(KeyValueEntry(key: "", value: "", isRevealed: true))
                } label: {
                    Label(addLabel, systemImage: "plus")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(themeColors.primaryAccent)
                }
                .buttonStyle(.plain)
            }

            if entries.isEmpty {
                Text("None configured")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundStyle(themeColors.mutedText)
                    .padding(.vertical, 4)
            } else {
                ForEach($entries) { $entry in
                    InspectorKeyValueRow(entry: $entry) {
                        entries.removeAll { $0.id == entry.id }
                    }
                }
            }
        }
    }
}

// MARK: - Row

private struct InspectorKeyValueRow: View {
    @Binding var entry: KeyValueEntry
    let onDelete: () -> Void

    @Environment(\.themeColors) private var themeColors
    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(spacing: 8) {
            TextField("KEY", text: $entry.key)
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(themeColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(fieldBackground)
                .frame(maxWidth: 180)

            Group {
                if entry.isRevealed {
                    TextField("value", text: $entry.value)
                } else {
                    SecureField("value", text: $entry.value)
                }
            }
            .textFieldStyle(.plain)
            .font(DesignTokens.Typography.codeSmall)
            .foregroundStyle(themeColors.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(fieldBackground)

            Button {
                entry.isRevealed.toggle()
            } label: {
                Image(systemName: entry.isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 11))
                    .foregroundStyle(themeColors.mutedText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(entry.isRevealed ? "Hide value" : "Reveal value")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(themeColors.errorColor.opacity(0.85))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(entry.key.isEmpty ? "entry" : entry.key)")
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(appearance.surface(themeColors.mainBackground, base: 0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(themeColors.borderColor, lineWidth: 1)
            )
    }
}
