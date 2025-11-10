//
//  BackgroundCircles.swift
//  project-fluency
//
//  Created by Harouna Thiam on 11/6/25.
//

// TODO: Make the gradient background animated.
// TODO: On click, make the 1) text and button disappear, 2) transition by either: 2.1) shrinking the circles and fade to white OR 2.2) expanding the circles and fade to grey

import SwiftUI

struct BackgroundCircles: View {
    @State private var animateGradient = false
    @State private var gradientPhase = false

    let colors: [Color] = [
        Color.gray.opacity(0.8),
        Color.gray.opacity(0.6),
        Color.gray.opacity(0.4),
        Color.gray.opacity(0.25),
        Color.gray.opacity(0.15),
        Color.gray.opacity(0.08),
        Color.gray.opacity(0.04),
        Color.gray.opacity(0.02)
    ]

    var body: some View {
        ZStack {
            // MARK: Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    animateGradient ? Color.gray.opacity(0.9) : Color.white.opacity(0.9),
                    animateGradient ? Color.white.opacity(0.6) : Color.gray.opacity(0.6),
                    animateGradient ? Color.gray.opacity(0.8) : Color.white.opacity(0.8)
                ]),
                startPoint: gradientPhase ? .topLeading : .bottomTrailing,
                endPoint: gradientPhase ? .bottomTrailing : .topLeading
            )
            .animation(
                .easeInOut(duration: 10)
                    .repeatForever(autoreverses: true),
                value: animateGradient
            )
            .ignoresSafeArea()

            // MARK: Layered circles
            ForEach(0..<colors.count, id: \.self) { index in
                Circle()
                    .fill(colors[index])
                    .frame(
                        width: CGFloat(800 + index * 120),
                        height: CGFloat(800 + index * 120)
                    )
                    //.offset(y: 300)
            }
        }
        .onAppear {
            animateGradient = true
            gradientPhase = true
        }
        .ignoresSafeArea()
    }
}
