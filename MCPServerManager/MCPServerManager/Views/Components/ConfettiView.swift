import SwiftUI

struct ConfettiView: View {
    let trigger: Bool
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiShape(shape: piece.shape)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .offset(x: piece.x, y: piece.y)
                    .rotationEffect(.degrees(piece.rotation))
                    .opacity(piece.opacity)
            }
        }
        .onChange(of: trigger) { newValue in
            if newValue {
                startConfetti()
            }
        }
    }

    private func startConfetti() {
        confettiPieces = []
        animate = false

        // Create confetti pieces
        for _ in 0..<50 {
            confettiPieces.append(
                ConfettiPiece(
                    x: CGFloat.random(in: -200...200),
                    y: -100,
                    size: CGFloat.random(in: 8...16),
                    color: randomColor(),
                    shape: ConfettiShapeType.allCases.randomElement() ?? .circle,
                    rotation: Double.random(in: 0...360),
                    opacity: 1.0
                )
            )
        }

        // Animate confetti falling
        withAnimation(.easeOut(duration: 2.0)) {
            for i in 0..<confettiPieces.count {
                confettiPieces[i].y = CGFloat.random(in: 400...800)
                confettiPieces[i].x += CGFloat.random(in: -100...100)
                confettiPieces[i].rotation += Double.random(in: 360...720)
                confettiPieces[i].opacity = 0.0
            }
        }

        // Clear confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            confettiPieces = []
        }
    }

    private func randomColor() -> Color {
        let colors: [Color] = [
            .red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan
        ]
        return colors.randomElement() ?? .blue
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var shape: ConfettiShapeType
    var rotation: Double
    var opacity: Double
}

enum ConfettiShapeType: CaseIterable {
    case circle
    case square
    case triangle
}

struct ConfettiShape: Shape {
    let shape: ConfettiShapeType

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:
            return Path(ellipseIn: rect)
        case .square:
            return Path(rect)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
}
