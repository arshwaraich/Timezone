//
//  SunPathChart.swift
//  timezone
//

import SwiftUI

struct SunPathChart: View {
    let width: CGFloat
    let height: CGFloat
    let timezones: [TimezoneEntry]
    let timezoneData: [String: TimezoneData]

    var centerY: CGFloat { height / 2 }
    var amplitude: CGFloat { height / 2.5 }

    private let hPadding: CGFloat = 16

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let drawLeft = hPadding
            let drawWidth = w - hPadding * 2
            let cY = h / 2
            let amp = h / 2.5

            // Horizon line
            let horizonPath = Path { p in
                p.move(to: CGPoint(x: 0, y: cY))
                p.addLine(to: CGPoint(x: w, y: cY))
            }
            context.stroke(
                horizonPath,
                with: .color(.white.opacity(0.15)),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )

            // Sine wave
            let wavePath = Path { p in
                for i in 0...200 {
                    let frac = CGFloat(i) / 200
                    let x = drawLeft + frac * drawWidth
                    let angle = frac * 2 * .pi - .pi / 2
                    let y = cY - sin(angle) * amp
                    if i == 0 {
                        p.move(to: CGPoint(x: x, y: y))
                    } else {
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            context.stroke(
                wavePath,
                with: .color(Color(red: 0.984, green: 0.749, blue: 0.141).opacity(0.85)),
                style: StrokeStyle(lineWidth: 3)
            )

            // Timezone markers
            for tz in timezones {
                guard let data = timezoneData[tz.zone] else { continue }
                let cx = drawLeft + (data.positionX / width) * drawWidth
                let cy = data.positionY / height * h

                // Circle
                let circle = Path(ellipseIn: CGRect(x: cx - 8, y: cy - 8, width: 16, height: 16))
                context.fill(circle, with: .color(tz.color))
                context.stroke(circle, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 2))

                // Label
                context.draw(
                    Text(tz.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white),
                    at: CGPoint(x: cx, y: cy - 18),
                    anchor: .center
                )
            }
        }
        .frame(width: width, height: height)
    }
}
