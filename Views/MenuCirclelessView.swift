import SwiftUI

struct MenuCirclelessView: View {
    @State private var animateBeams = false
    @State private var vignetteIntensity: Double = 0.7
    @State private var showBackgroundCircles = false
    @State private var buttonOpacity: [Double] = [0, 0]
    
    var body: some View {
        ZStack {
            // 🌫 Background base
            Color.gray
                .ignoresSafeArea()
            
            // Background decorative circles (optional layer)
            BackgroundCircles()
                .opacity(showBackgroundCircles ? 0.7 : 0)
                .animation(.easeInOut(duration: 1), value: showBackgroundCircles)
            
            // 🌤 Light beams
            ForEach(0..<4, id: \.self) { i in
                LightBeam(
                    width: CGFloat.random(in: 40...90),
                    height: 1000,
                    xOffset: CGFloat.random(in: -220...220),
                    delay: Double.random(in: 0...4),
                    duration: Double.random(in: 6...10)
                )
                .opacity(animateBeams ? 1 : 0)
                .animation(
                    .easeInOut(duration: 3)
                        .delay(Double(i) * 0.5),
                    value: animateBeams
                )
            }
            
            // 🔦 Vignette spotlight
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.0), location: 0.45),
                    .init(color: .black.opacity(vignetteIntensity), location: 1.0)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 700
            )
            .ignoresSafeArea()
            .blur(radius: 8)
            .animation(.easeInOut(duration: 4.5), value: vignetteIntensity)
        }
        .onAppear {
            animateBeams = true
            
            // Fade background decorative circles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showBackgroundCircles = true
            }
            
            // Ease-in vignette
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    vignetteIntensity = 0.35
                }
            }
        }
    }
}
