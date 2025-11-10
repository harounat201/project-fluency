import SwiftUI

// DESIGN METHODOLOGY:
// Muted colors, until we get to the theraputic functionality.

struct TitleView: View {
    @State private var startJourney = false
    @Namespace private var animation

    var body: some View {
        ZStack {
            if !startJourney {
                ZStack {
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.0), location: 0.45),
                            .init(color: .black.opacity(0.3), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 700
                    )
                    .blendMode(.multiply)
                    .ignoresSafeArea()
                    .blur(radius: 8)
                    
                    BackgroundCircles()
                        .opacity(0.9)

                    // Floating shapes (existing)
                    ForEach(0..<14, id: \.self) { _ in
                        FloatingShape(
                            color: Color.white.opacity(Double.random(in: 0.1...0.3)),
                            size: CGFloat.random(in: 60...150)
                        )
                        .blur(radius: CGFloat.random(in: 6...14))
                        .offset(
                            x: CGFloat.random(in: -180...180),
                            y: CGFloat.random(in: -400...300)
                        )
                    }

                    // 💡 Light Beams Layer
                    ForEach(0..<4, id: \.self) { i in
                        LightBeam(
                            width: CGFloat.random(in: 40...80),
                            height: 1000,
                            xOffset: CGFloat.random(in: -300...300),
                            delay: Double.random(in: 0...3),
                            duration: Double.random(in: 6...20)
                        )
                    }
                }
                .scaleEffect(startJourney ? 0.1 : 1.0)
                .animation(.easeInOut(duration: 3), value: startJourney)

                // Foreground text + button
                VStack(spacing: 40) {
                    Text("Chorus")
                        .font(.system(size: 90, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(startJourney ? 0 : 1)
                        .animation(.easeOut(duration: 3), value: startJourney)

                    Button(action: {
                        withAnimation {
                            startJourney = true
                        }
                    }) {
                        Text("Start the Experience")
                            .font(.headline)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.gray)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .opacity(startJourney ? 0 : 1)
                    .animation(.easeOut(duration: 3), value: startJourney)
                }

            } else {
                IntroView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

