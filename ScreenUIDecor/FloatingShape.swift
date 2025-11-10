import SwiftUI

struct FloatingShape: View {
    let color: Color
    let size: CGFloat

    @State private var randomX: CGFloat = .random(in: -200...200)
    @State private var randomY: CGFloat = .random(in: -400...350)
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: randomX, y: randomY + floatOffset)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 3.5...6.5))
                        .repeatForever(autoreverses: true)
                ) {
                    floatOffset = CGFloat.random(in: -40...40)
                }
            }
    }
}
