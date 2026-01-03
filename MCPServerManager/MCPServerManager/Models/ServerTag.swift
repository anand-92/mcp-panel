import Foundation

enum ServerTag: String, Codable, CaseIterable, Identifiable {
    case ui = "UI"
    case backend = "Backend"
    case creativity = "Creativity"
    case devOps = "Dev Ops"
    case advanced = "Advanced"

    var id: String { rawValue }
}
