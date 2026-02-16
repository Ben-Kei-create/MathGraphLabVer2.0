//
//  LocusOverlayView.swift
//  MathGraph Lab
//

import SwiftUI

struct LocusOverlayView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            if appState.isLocusModeActive {
                let system = CoordinateSystem(
                    size: geometry.size,
                    zoomScale: appState.zoomScale,
                    panOffset: appState.panOffset
                )
                let pointA = appState.locusPointA
                let ax = Double(pointA.x)
                let ay = Double(pointA.y)
                let screenA = system.screenPosition(mathX: ax, mathY: ay)

                ZStack {
                    tracePath(system: system)
                        .stroke(.green, style: StrokeStyle(lineWidth: 1.2))

                    Rectangle()
                        .fill(.orange)
                        .frame(width: 12, height: 12)
                        .overlay(Rectangle().stroke(.white.opacity(0.9), lineWidth: 1.5))
                        .position(screenA)

                    Text("A")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .position(x: screenA.x + 14, y: screenA.y - 14)

                    if appState.isMotionModeActive {
                        let t = appState.movingPointT
                        let py = appState.parabola.evaluate(at: t)
                        let mx = (t + ax) / 2.0
                        let my = (py + ay) / 2.0
                        let screenP = system.screenPosition(mathX: t, mathY: py)
                        let screenM = system.screenPosition(mathX: mx, mathY: my)

                        Path { path in
                            path.move(to: screenP)
                            path.addLine(to: screenA)
                        }
                        .stroke(.green.opacity(0.55), style: StrokeStyle(lineWidth: 1.1, dash: [4, 3]))

                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1.5))
                            .position(screenM)

                        Text("M")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .position(x: screenM.x + 14, y: screenM.y - 14)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func tracePath(system: CoordinateSystem) -> Path {
        var path = Path()
        var isFirstPoint = true
        let step = 0.08
        let ax = Double(appState.locusPointA.x)
        let ay = Double(appState.locusPointA.y)

        for t in stride(from: -10.0, through: 10.0, by: step) {
            let py = appState.parabola.evaluate(at: t)
            let mx = (t + ax) / 2.0
            let my = (py + ay) / 2.0
            let point = system.screenPosition(mathX: mx, mathY: my)

            if isFirstPoint {
                path.move(to: point)
                isFirstPoint = false
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}
