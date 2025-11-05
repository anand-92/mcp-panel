import SwiftUI

struct FloatingParticlesView: View {
    @State private var particles: [Particle] = []
    let particleCount: Int
    let colors: [Color]

    init(particleCount: Int = 20, colors: [Color] = [.cyan.opacity(0.3), .blue.opacity(0.3), .purple.opacity(0.3)]) {
        self.particleCount = particleCount
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    particle.color,
                                    particle.color.opacity(0.5),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: particle.size / 2
                            )
                        )
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.blur)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                startAnimation(in: geometry.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func initializeParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 40...120),
                color: colors.randomElement() ?? .blue.opacity(0.3),
                blur: CGFloat.random(in: 20...40),
                opacity: Double.random(in: 0.2...0.6),
                velocityX: CGFloat.random(in: -0.5...0.5),
                velocityY: CGFloat.random(in: -0.5...0.5)
            )
        }
    }

    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                for i in 0..<particles.count {
                    // Update position
                    particles[i].x += particles[i].velocityX
                    particles[i].y += particles[i].velocityY

                    // Wrap around screen edges
                    if particles[i].x < -particles[i].size {
                        particles[i].x = size.width + particles[i].size
                    } else if particles[i].x > size.width + particles[i].size {
                        particles[i].x = -particles[i].size
                    }

                    if particles[i].y < -particles[i].size {
                        particles[i].y = size.height + particles[i].size
                    } else if particles[i].y > size.height + particles[i].size {
                        particles[i].y = -particles[i].size
                    }

                    // Subtle opacity pulsing
                    particles[i].pulsePhase += 0.02
                    particles[i].opacity = particles[i].baseOpacity + sin(particles[i].pulsePhase) * 0.2
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var blur: CGFloat
    var opacity: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
    var pulsePhase: Double = 0
    var baseOpacity: Double

    init(x: CGFloat, y: CGFloat, size: CGFloat, color: Color, blur: CGFloat, opacity: Double, velocityX: CGFloat, velocityY: CGFloat) {
        self.x = x
        self.y = y
        self.size = size
        self.color = color
        self.blur = blur
        self.opacity = opacity
        self.baseOpacity = opacity
        self.velocityX = velocityX
        self.velocityY = velocityY
    }
}
