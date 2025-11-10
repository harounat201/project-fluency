import SwiftUI

struct IntroView: View {
    @State private var fadeInBackground = false
    @State private var currentIndex = 0
    @State private var showText = false
    @State private var animateBeams = false
    @State private var showBeams = true
    @State private var showVignette = false
    @State private var showNextButton = false
    @State private var showCircles = true
    @State private var goToMenu = false

    let messages = [
        "Welcome to Chorus.",
        "One in five children live with a Neurodevelopmental Speech Disorder.",
        "As they grow older, about 15% continue to stutter — carrying it into adulthood.",
        "That means roughly 1% of adults worldwide speak with some form of disfluency, or stutter.",
        "Chorus isn’t here to 'fix' speech. It's here to educate — and to celebrate every speaking cadence, traditional or non-traditional.",
        "Take a journey to understand the characteristics and physical effects of a stutter — and discover the research-backed methods that help speech flow with confidence."
    ]

    var body: some View {
        ZStack {
            // 🌀 Background layers
            ZStack {
                Color.gray
                    .opacity(fadeInBackground ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.5), value: fadeInBackground)
                    .ignoresSafeArea()

                // Floating circles
                ForEach(0..<14, id: \.self) { _ in
                    FloatingShape(
                        color: Color.white.opacity(Double.random(in: 0.03...0.15)),
                        size: CGFloat.random(in: 70...160)
                    )
                    .blur(radius: CGFloat.random(in: 6...14))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...350)
                    )
                    .opacity(showCircles ? 1 : 0)
                    .scaleEffect(showCircles ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 1.5), value: showCircles)
                }

                // Light beams
                ForEach(0..<4, id: \.self) { i in
                    LightBeam(
                        width: CGFloat.random(in: 40...90),
                        height: 1000,
                        xOffset: CGFloat.random(in: -220...220),
                        delay: Double.random(in: 0...4),
                        duration: Double.random(in: 6...10)
                    )
                    .opacity(showBeams ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5), value: showBeams)
                }
            }

            // 🔦 Vignette
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.0), location: 0.45),
                    .init(color: .black.opacity(showVignette ? 0.6 : 0.0), location: 1.0)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 700
            )
            .blendMode(.multiply)
            .ignoresSafeArea()
            .blur(radius: 8)

            // 📝 Text + Button VStack
            VStack(spacing: 60) { // 👈 adjust spacing here
                // Text sequence
                ZStack {
                    ForEach(messages.indices, id: \.self) { index in
                        if index == currentIndex {
                            Text(messages[index])
                                .font(.title)
                                .fontWeight(index == messages.count - 1 ? .bold : .semibold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(showText ? 1 : 0)
                                .transition(.opacity)
                                .shadow(radius: 4)
                        }
                    }
                }
                .animation(.easeInOut(duration: 1.2), value: currentIndex)

                // “Next” button (below text)
                if showNextButton {
                    Button(action: {
                        // Fade out all elements before transition
                        withAnimation(.easeInOut(duration: 1.5)) {
                            showNextButton = false
                            showText = false
                            showCircles = false
                            showBeams = false
                        }

                        // Optional: darken vignette slightly
                        withAnimation(.easeInOut(duration: 1.5)) {
                            showVignette = true
                        }

                        // Delay transition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            goToMenu = true
                        }
                    }) {
                        Text("Next")
                            .font(.headline)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.gray)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .transition(.opacity)
                    .opacity(showNextButton ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5), value: showNextButton)
                }
            }
            .padding(.bottom, 200) // moves entire text/button block up slightly
            
            // 🆕 Transition destination
            if goToMenu {
                MenuView()
                    .transition(.identity)
                    .animation(nil, value: goToMenu)
            }
        }
        .onAppear {
            fadeInBackground = true
            animateBeams = true

            // 🎬 Delay vignette
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 2.5)) {
                    showVignette = true
                }
            }

            // ⏳ Delay first text
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    showText = true
                }
            }

            // Timing
            let fadeDuration = 1.2
            let holdDuration = 3.0
            let gapDuration = 0.6
            let initialDelay = 2.0 + fadeDuration + holdDuration

            // 🔁 Text loop
            for i in 1..<messages.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + Double(i - 1) * (fadeDuration * 2 + holdDuration + gapDuration)) {
                    withAnimation(.easeInOut(duration: fadeDuration)) {
                        showText = false
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + Double(i - 1) * (fadeDuration * 2 + holdDuration + gapDuration) + fadeDuration + gapDuration) {
                    withAnimation(.easeInOut(duration: fadeDuration)) {
                        currentIndex = i
                        showText = true
                    }

                    if i == messages.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration + 0.5) {
                            withAnimation(.easeInOut(duration: 2)) {
                                showNextButton = true
                            }
                        }
                    }
                }
            }
        }
    }
}
