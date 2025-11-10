import SwiftUI

struct MenuView: View {
    @State private var animateBeams = false
    @State private var showCircles = false
    @State private var vignetteIntensity: Double = 0.6
    @State private var showBackgroundCircles = false
    @State private var buttonOpacity: [Double] = [0, 0]
    
    // Each circle has its own random position that changes over time
    @State private var circleOffsets: [CGSize] = (0..<12).map { _ in
        CGSize(width: CGFloat.random(in: -200...200), height: CGFloat.random(in: -400...350))
    }
    
    var body: some View {
        ZStack {
            // 🌫 Background base
            Color.gray
                .ignoresSafeArea()
            
            BackgroundCircles()
                .opacity(showBackgroundCircles ? 0.7 : 0)
                .animation(.easeInOut(duration: 1), value: showBackgroundCircles)
            
            // 💫 Floating circles that drift slowly
            ZStack {
                ForEach(0..<circleOffsets.count, id: \.self) { i in
                    FloatingShape(
                        color: Color.white.opacity(Double.random(in: 0.08...0.25)),
                        size: CGFloat.random(in: 70...160)
                    )
                    .blur(radius: CGFloat.random(in: 6...14))
                    .offset(x: circleOffsets[i].width, y: circleOffsets[i].height)
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
                .animation(.easeInOut(duration: 3).delay(Double(i) * 0.5), value: animateBeams)
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
            
            // 🧩 Menu buttons
            VStack(spacing: 30) {
                menuButton(title: "The Neurology of Speech Impediments", index: 0)
                menuButton(title: "Choral Speech Therapeutic Simulator", index: 1)
            }
        }
        .onAppear {
            animateBeams = true
            
            // Fade in circles & background
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCircles = true
                showBackgroundCircles = true
            }
            
            // Dial back vignette
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    vignetteIntensity = 0.35
                }
            }
            
            // 🌟 Fade buttons one by one from bottom → top
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                for i in buttonOpacity.indices {
                    withAnimation(.easeInOut(duration: 1.0).delay(Double(buttonOpacity.count - 1 - i) * 0.8)) {
                        buttonOpacity[i] = 1.0
                    }
                }
            }
            
            // 🌊 Start continuous circle motion
            startCircleDrift()
        }
    }
    
    // MARK: - Button Builder
    func menuButton(title: String, index: Int) -> some View {
        Button(action: { /* TBD */ }) {
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(width: 500, height: 50)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                        .blur(radius: 0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.gray.opacity(0.05), lineWidth: 1)
                )
                //.shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        }
        .opacity(buttonOpacity[index])
    }
    
    // MARK: - Continuous Circle Drift Animation
    func startCircleDrift() {
        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 6.0)) {
                for i in circleOffsets.indices {
                    // Move each circle to a new random location within range
                    circleOffsets[i] = CGSize(
                        width: CGFloat.random(in: -220...220),
                        height: CGFloat.random(in: -400...350)
                    )
                }
            }
        }
    }
}
