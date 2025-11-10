import SwiftUI

struct LiquidGlassText: View {
    let text: String
    let fontSize: CGFloat
    @State private var shimmer = false
    @State private var reflect = false

    var body: some View {
        ZStack {
            // BACKDROP BLUR (keeps transparency)
            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 80, style: .continuous))
                .overlay(
                    // Adaptive light pickup
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 80)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .frame(width: fontSize * 4.2, height: fontSize * 1.6)
                .shadow(color: .black.opacity(0.18), radius: 25, x: 0, y: 12)
                .compositingGroup()
                .overlay(
                    // Reflection pass — moving highlight sweep
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.25)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.screen)
                    .opacity(0.8)
                    .blur(radius: 1.2)
                    .rotationEffect(.degrees(reflect ? 20 : -20))
                    .offset(x: reflect ? 180 : -180)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: reflect)
                    .clipShape(RoundedRectangle(cornerRadius: 80, style: .continuous))
                )
                .overlay(
                    // Subtle background distortion shimmer
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.overlay)
                    .blur(radius: 2)
                    .opacity(0.3)
                    .mask(
                        RoundedRectangle(cornerRadius: 80)
                            .stroke(lineWidth: 2)
                            .blur(radius: 3)
                    )
                )

            // TEXT LAYER
            Text(text)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.25), radius: 10, x: 0, y: 1)
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 3)
        }
        .onAppear {
            shimmer = true
            reflect = true
        }
        .clipShape(RoundedRectangle(cornerRadius: 80, style: .continuous))
        .compositingGroup()
    }
}
