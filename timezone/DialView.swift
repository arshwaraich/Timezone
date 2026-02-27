//
//  DialView.swift
//  timezone
//

import SwiftUI

struct DialView: View {
    @Binding var dialOffset: CGFloat
    @Binding var timeOffset: Double
    @GestureState private var dragOffset: CGFloat = 0
    private let pixelsPerHour: CGFloat = 20
    private let markSpacing: CGFloat = 4
    @State private var lastMajorMarkIndex: Int = 0
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let majorMarkSpacing: CGFloat = 40 // markSpacing * 10

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dial marks
                Canvas { context, size in
                    let totalOffset = dialOffset + dragOffset
                    let wrappedOffset = totalOffset.truncatingRemainder(dividingBy: 200)
                    let startMark = -20
                    let endMark = Int(size.width / 4) + 20

                    for i in startMark...endMark + 150 {
                        let isMajor = i % 10 == 0
                        let isMinor = i % 5 == 0
                        let x = CGFloat(i) * 4 + wrappedOffset - 200
                        let markHeight: CGFloat
                        let markWidth: CGFloat
                        let markColor: Color

                        if isMajor {
                            markHeight = 36
                            markWidth = 2
                            markColor = Color(white: 0.75)
                        } else if isMinor {
                            markHeight = 22
                            markWidth = 2
                            markColor = Color(white: 0.45)
                        } else {
                            markHeight = 14
                            markWidth = 1
                            markColor = Color(white: 0.35)
                        }

                        let rect = CGRect(
                            x: x - markWidth / 2,
                            y: (size.height - markHeight) / 2,
                            width: markWidth,
                            height: markHeight
                        )
                        context.fill(Path(rect), with: .color(markColor))
                    }
                }

                // Center indicator
                Rectangle()
                    .fill(Color(red: 0.957, green: 0.247, blue: 0.369)) // rose-500
                    .frame(width: 2)
            }
        }
        .frame(height: 70)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    dialOffset += value.translation.width
                    timeOffset = Double(-(dialOffset / pixelsPerHour))
                }
        )
        .onChange(of: dragOffset) {
            let currentTotal = dialOffset + dragOffset
            timeOffset = Double(-(currentTotal / pixelsPerHour))

            let majorMark = Int(round(currentTotal / majorMarkSpacing))
            if majorMark != lastMajorMarkIndex {
                lightImpact.impactOccurred()
                lastMajorMarkIndex = majorMark
            }
        }
        .onAppear {
            lightImpact.prepare()
        }
    }
}
