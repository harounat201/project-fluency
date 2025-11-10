//
//  LightBeam.swift
//  project-fluency
//
//  Created by Harouna Thiam on 11/7/25.
//


import SwiftUI

struct LightBeam: View {
    @State private var appear = false
    let width: CGFloat
    let height: CGFloat
    let xOffset: CGFloat
    let delay: Double
    let duration: Double

    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white.opacity(0.0), location: 0.0),
                .init(color: .white.opacity(0.25), location: 0.5),
                .init(color: .white.opacity(0.0), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: width, height: height)
        .opacity(appear ? 0.7 : 0.0)
        .blur(radius: 25)
        .offset(x: xOffset)
        .animation(
            .easeInOut(duration: duration)
                .delay(delay)
                .repeatForever(autoreverses: true),
            value: appear
        )
        .onAppear {
            appear = true
        }
    }
}
