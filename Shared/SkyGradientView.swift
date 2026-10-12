//
//  SkyGradientView.swift
//  timezone
//

import SwiftUI

struct SkyGradientView: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.035, green: 0.035, blue: 0.043), location: 0),
                .init(color: Color(red: 0.094, green: 0.094, blue: 0.106), location: 0.125),
                .init(color: Color(red: 0.153, green: 0.153, blue: 0.165), location: 0.167),
                .init(color: Color(red: 0.247, green: 0.247, blue: 0.275), location: 0.20),
                .init(color: Color(red: 0.918, green: 0.345, blue: 0.047), location: 0.208),
                .init(color: Color(red: 0.976, green: 0.451, blue: 0.086), location: 0.23),
                .init(color: Color(red: 0.984, green: 0.573, blue: 0.235), location: 0.25),
                .init(color: Color(red: 0.984, green: 0.749, blue: 0.141), location: 0.292),
                .init(color: Color(red: 0.024, green: 0.714, blue: 0.831), location: 0.333),
                .init(color: Color(red: 0.024, green: 0.714, blue: 0.831), location: 0.50),
                .init(color: Color(red: 0.024, green: 0.714, blue: 0.831), location: 0.667),
                .init(color: Color(red: 0.984, green: 0.749, blue: 0.141), location: 0.708),
                .init(color: Color(red: 0.984, green: 0.573, blue: 0.235), location: 0.75),
                .init(color: Color(red: 0.976, green: 0.451, blue: 0.086), location: 0.77),
                .init(color: Color(red: 0.918, green: 0.345, blue: 0.047), location: 0.792),
                .init(color: Color(red: 0.247, green: 0.247, blue: 0.275), location: 0.80),
                .init(color: Color(red: 0.153, green: 0.153, blue: 0.165), location: 0.833),
                .init(color: Color(red: 0.094, green: 0.094, blue: 0.106), location: 0.875),
                .init(color: Color(red: 0.035, green: 0.035, blue: 0.043), location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct TwinklingStarView: View {
    let star: Star
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: star.size, height: star.size)
            .shadow(color: .white.opacity(0.8), radius: 2)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(star.delay)
                ) {
                    opacity = 1.0
                }
            }
    }
}

struct StarsOverlay: View {
    let stars: [Star]

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                let isInNightZone = star.x < 19 || star.x > 81
                if isInNightZone {
                    TwinklingStarView(star: star)
                        .position(
                            x: star.x / 100 * geo.size.width,
                            y: star.y / 100 * geo.size.height
                        )
                }
            }
        }
    }
}
