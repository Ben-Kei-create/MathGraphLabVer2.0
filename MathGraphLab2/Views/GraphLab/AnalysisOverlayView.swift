//
//  AnalysisOverlayView.swift
//  MathGraph Lab
//
//  Layer 3: Intersection points, droplines, area visualization, and smart labels
//  Implements IDD Section 3.2 Layer 3 specifications
//

import SwiftUI

// MARK: - Analysis Overlay View
/// Renders intersection points, droplines, filled area triangles, and coordinate/area labels
struct AnalysisOverlayView: View {

    @EnvironmentObject var appState: AppState

    // Visual configuration
    private let intersectionDotRadius: CGFloat = 6.0
    private let droplineWidth: CGFloat = 1.5
    private let areaOpacity: Double = 0.3
    private let labelOffsetAbovePoint: CGFloat = 20.0
    private let labelPadding: CGSize = CGSize(width: 10, height: 5)

    var body: some View {
        Canvas { context, size in
            let coordSystem = CoordinateSystem(
                size: size,
                zoomScale: appState.zoomScale,
                panOffset: appState.panOffset
            )

            // Calculate intersection points using MathSolver
            let intersections = MathSolver.solveIntersections(
                parabola: appState.parabola,
                line: appState.line
            )

            // Store intersections in AppState for other components
            DispatchQueue.main.async {
                appState.intersectionPoints = intersections
            }

            // Draw area fill if mode is enabled and we have 2 intersections
            if appState.isAreaModeEnabled && intersections.count == 2 {
                drawAreaTriangle(
                    context: context,
                    coordSystem: coordSystem,
                    intersections: intersections
                )

                drawAreaLabel(
                    context: context,
                    coordSystem: coordSystem,
                    intersections: intersections
                )
            }

            if appState.showIntersectionHighlights {
                // Draw droplines from intersections to X-axis
                drawDroplines(
                    context: context,
                    coordSystem: coordSystem,
                    intersections: intersections
                )

                // Draw intersection points (green dots)
                drawIntersectionPoints(
                    context: context,
                    coordSystem: coordSystem,
                    intersections: intersections
                )

                // Draw smart labels (x, y) above each intersection
                drawIntersectionLabels(
                    context: context,
                    coordSystem: coordSystem,
                    intersections: intersections
                )
            }
        }
    }
    
    // MARK: - Drawing Methods
    
    /// Draw green dots at intersection points
    /// IDD Section 5: Intersections are System Green
    private func drawIntersectionPoints(
        context: GraphicsContext,
        coordSystem: CoordinateSystem,
        intersections: [IntersectionPoint]
    ) {
        for point in intersections {
            let screenPos = coordSystem.screenPosition(mathX: point.x, mathY: point.y)
            
            // Draw outer glow
            let glowCircle = Circle()
                .path(in: CGRect(
                    x: screenPos.x - intersectionDotRadius - 2,
                    y: screenPos.y - intersectionDotRadius - 2,
                    width: (intersectionDotRadius + 2) * 2,
                    height: (intersectionDotRadius + 2) * 2
                ))
            
            context.fill(
                glowCircle,
                with: .color(Color.green.opacity(0.3))
            )
            
            // Draw main dot
            let circle = Circle()
                .path(in: CGRect(
                    x: screenPos.x - intersectionDotRadius,
                    y: screenPos.y - intersectionDotRadius,
                    width: intersectionDotRadius * 2,
                    height: intersectionDotRadius * 2
                ))
            
            context.fill(circle, with: .color(Color.green))
            
            // Draw white border
            context.stroke(
                circle,
                with: .color(Color.white),
                lineWidth: 2.0
            )
        }
    }

    /// Draw coordinate labels (x, y) above each intersection as capsule badges
    private func drawIntersectionLabels(
        context: GraphicsContext,
        coordSystem: CoordinateSystem,
        intersections: [IntersectionPoint]
    ) {
        let mode = appState.coefficientInputMode
        let isDark = appState.appTheme != .light
        let labelBg = isDark ? Color(white: 0.2).opacity(0.95) : Color.white.opacity(0.95)
        let labelFg = isDark ? Color.white : Color.primary

        for point in intersections {
            let screenPos = coordSystem.screenPosition(mathX: point.x, mathY: point.y)
            let labelCenter = CGPoint(x: screenPos.x, y: screenPos.y - labelOffsetAbovePoint)
            let coordString = formatCoordinate(x: point.x, y: point.y, mode: mode)

            let text = Text(coordString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(labelFg)

            let textSize = CGSize(width: 100, height: 20)
            let capsuleRect = CGRect(
                x: labelCenter.x - textSize.width / 2,
                y: labelCenter.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            let capsulePath = Capsule().path(in: capsuleRect)
            let shadowPath = Capsule().path(in: capsuleRect.offsetBy(dx: 0, dy: 1))

            context.fill(shadowPath, with: .color(Color.black.opacity(0.12)))
            context.fill(capsulePath, with: .color(labelBg))
            context.stroke(
                capsulePath,
                with: .color(Color.primary.opacity(0.15)),
                lineWidth: 0.5
            )
            context.draw(
                text,
                at: CGPoint(x: capsuleRect.midX, y: capsuleRect.midY),
                anchor: .center
            )
        }
    }

    /// Draw dashed lines from intersection points to X-axis
    private func drawDroplines(
        context: GraphicsContext,
        coordSystem: CoordinateSystem,
        intersections: [IntersectionPoint]
    ) {
        for point in intersections {
            let topPoint = coordSystem.screenPosition(mathX: point.x, mathY: point.y)
            let bottomPoint = coordSystem.screenPosition(mathX: point.x, mathY: 0)
            
            var path = Path()
            path.move(to: topPoint)
            path.addLine(to: bottomPoint)
            
            context.stroke(
                path,
                with: .color(Color.green.opacity(0.6)),
                style: StrokeStyle(
                    lineWidth: droplineWidth,
                    dash: [4, 4]
                )
            )
        }
    }
    
    /// Draw filled area triangle: Vertex V(p,q) + intersection points A, B
    private func drawAreaTriangle(
        context: GraphicsContext,
        coordSystem: CoordinateSystem,
        intersections: [IntersectionPoint]
    ) {
        guard intersections.count == 2 else { return }

        let triangle = areaTriangleVertices(intersections: intersections)
        let p1 = coordSystem.screenPosition(mathX: triangle.p1.x, mathY: triangle.p1.y)
        let p2 = coordSystem.screenPosition(mathX: triangle.p2.x, mathY: triangle.p2.y)
        let p3 = coordSystem.screenPosition(mathX: triangle.p3.x, mathY: triangle.p3.y)

        // 塗りつぶし
        var fillPath = Path()
        fillPath.move(to: p1)
        fillPath.addLine(to: p2)
        fillPath.addLine(to: p3)
        fillPath.closeSubpath()

        context.fill(
            fillPath,
            with: .color(Color.green.opacity(areaOpacity))
        )

        // アウトライン
        context.stroke(
            fillPath,
            with: .color(Color.green.opacity(0.5)),
            style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
        )
    }
    
    /// Draw area value label using vertex-based triangle: V(p,q), A, B
    private func drawAreaLabel(
        context: GraphicsContext,
        coordSystem: CoordinateSystem,
        intersections: [IntersectionPoint]
    ) {
        guard intersections.count == 2 else { return }

        let triangle = areaTriangleVertices(intersections: intersections)
        let area = triangleArea(
            triangle.p1,
            triangle.p2,
            triangle.p3
        )

        let mode = appState.coefficientInputMode
        let areaString = mode == .decimal
            ? String(format: "%.2f", area)
            : Self.fractionString(for: area)
        let areaLabel = "S = \(areaString)"

        // ラベルを三角形の重心に配置
        let centroidX = (triangle.p1.x + triangle.p2.x + triangle.p3.x) / 3.0
        let centroidY = (triangle.p1.y + triangle.p2.y + triangle.p3.y) / 3.0
        let labelPos = coordSystem.screenPosition(mathX: centroidX, mathY: centroidY)

        let areaText = Text(areaLabel)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.green)

        let textSize = CGSize(width: 88, height: 24)
        let backgroundRect = CGRect(
            x: labelPos.x - textSize.width / 2,
            y: labelPos.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        context.fill(
            Path(roundedRect: backgroundRect, cornerRadius: 6),
            with: .color(Color.black.opacity(0.7))
        )
        context.draw(areaText, at: CGPoint(x: backgroundRect.midX, y: backgroundRect.midY), anchor: .center)
    }

    // MARK: - Number format helpers (decimal / fraction)

    private func formatCoordinate(x: Double, y: Double, mode: AppState.InputMode) -> String {
        switch mode {
        case .decimal:
            return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
        case .fraction:
            return "(\(Self.fractionString(for: x)), \(Self.fractionString(for: y)))"
        }
    }

    /// 小数を分数表記に変換（教科書風）。整数はそのまま、それ以外は 1/100 単位で約分。
    private static func fractionString(for value: Double) -> String {
        let tol = 1e-6
        if abs(value - value.rounded()) < tol {
            return "\(Int(value.rounded()))"
        }
        let sign: Int = value < 0 ? -1 : 1
        let a = Int(round(abs(value) * 100))
        let b = 100
        let g = gcd(a, b)
        let num = sign * (a / g)
        let den = b / g
        if den == 1 { return "\(num)" }
        return "\(num)/\(den)"
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? abs(a) : gcd(b, a % b)
    }

    private func areaTriangleVertices(
        intersections: [IntersectionPoint]
    ) -> (p1: (x: Double, y: Double), p2: (x: Double, y: Double), p3: (x: Double, y: Double)) {
        let p1: (x: Double, y: Double) = appState.isAreaFromOrigin
            ? (0.0, 0.0)
            : (appState.parabola.p, appState.parabola.q)
        let p2 = (intersections[0].x, intersections[0].y)
        let p3 = (intersections[1].x, intersections[1].y)
        return (p1, p2, p3)
    }

    private func triangleArea(
        _ a: (x: Double, y: Double),
        _ b: (x: Double, y: Double),
        _ c: (x: Double, y: Double)
    ) -> Double {
        0.5 * abs(
            a.x * (b.y - c.y) +
            b.x * (c.y - a.y) +
            c.x * (a.y - b.y)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        GridBackgroundView()
        GraphCanvasView()
        AnalysisOverlayView()
    }
    .environmentObject(AppState())
}
