import SwiftUI

// TODO: Redo floating circle logic

struct MenuView: View {
    @State private var animateBeams = false
    @State private var showCircles = false
    @State private var vignetteIntensity: Double = 0.6
    @State private var showBackgroundCircles = false
    @State private var buttonOpacity: [Double] = [0, 0]
    
    @State private var circleOffsets: [CGSize] = (0..<12).map { _ in
        CGSize(width: CGFloat.random(in: -200...200),
               height: CGFloat.random(in: -400...350))
    }
    
    var body: some View {
        ZStack {
            // 🌫 Background base
            Color(white: 0.3)
                .ignoresSafeArea()
            
            BackgroundCircles()
                .opacity(showBackgroundCircles ? 0.7 : 0)
                .animation(.easeInOut(duration: 1), value: showBackgroundCircles)
            
            // 💫 Floating circles
            ZStack {
                ForEach(0..<circleOffsets.count, id: \.self) { i in
                    FloatingShape(
                        color: Color.white.opacity(Double.random(in: 0.08...0.25)),
                        size: CGFloat.random(in: 70...160)
                    )
                    .blur(radius: CGFloat.random(in: 6...14))
                    .offset(circleOffsets[i])
                    .opacity(showCircles ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5), value: showCircles)
                }
            }
            
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
                .animation(.easeInOut(duration: 3).delay(Double(i) * 0.5),
                           value: animateBeams)
            }
            
            // 🔦 Vignette
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.0), location: 0.45),
                    .init(color: .black.opacity(vignetteIntensity), location: 1.0)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 700
            )
            .blendMode(.multiply)
            .ignoresSafeArea()
            .blur(radius: 8)
            .animation(.easeInOut(duration: 4.5), value: vignetteIntensity)
            
            // 🧩 Menu buttons placeholder
            // (Leave empty for now; this restores layout integrity)
            VStack { }
        }
        .onAppear {
            animateBeams = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCircles = true
                showBackgroundCircles = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    vignetteIntensity = 0.35
                }
            }
            
            startCircleDrift()
        }
        
        // Button3DView()
    }
    
    func startCircleDrift() {
        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 6.0)) {
                    for i in circleOffsets.indices {
                        circleOffsets[i] = CGSize(
                            width: CGFloat.random(in: -220...220),
                            height: CGFloat.random(in: -400...350)
                        )
                    }
                }
            }
        }
    }
}
