//
//  GraphLabView.swift
//  MathGraph Lab
//
//  Main workspace with banner ad at bottom
//

import SwiftUI
import PencilKit

struct GraphLabView: View {
    
    @EnvironmentObject var appState: AppState
    @StateObject private var missionManager = MissionManager()
    
    var body: some View {
        // ★ここが重要！これがないと上のバーが出ません
        NavigationStack {
            VStack(spacing: 0) {
                // メイングラフエリア
                ZStack {
                    GridBackgroundView()
                    GraphCanvasView()
                    AnalysisOverlayView()
                    MarkedPointsOverlayView()
                    DistanceLinesOverlayView()
                    LocusOverlayView()
                    MovingPointOverlayView()
                // 数式オーバーレイ
                    EquationOverlayView()
                    
                    // ミッションオーバーレイ
                    MissionOverlayView(missionManager: missionManager)
                    
                    // 指移動（パン/ズーム）を有効にするためここに配置
                    TouchInteractionView()

                    DrawingCanvasView(
                        canvasView: Binding(
                            get: { appState.canvasView },
                            set: { appState.canvasView = $0 }
                        ),
                        isDrawingMode: $appState.isDrawingMode
                    )
                    
                    VStack {
                        Spacer()
                        ControlPanelOverlay()
                    }
                }
                .background(getBackgroundColor())
                
                // 広告バナーエリア
                if !appState.isAdRemoved {
                    BannerAdView()
                        .frame(height: 60)
                        .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 18) {
                        ShareButton()
                        ThemeMenuButton()
                        QuizToggleButton(isActive: missionManager.isMissionActive) {
                            withAnimation {
                                if missionManager.isMissionActive {
                                    missionManager.stop()
                                } else {
                                    missionManager.start()
                                }
                            }
                        }
                        DrawingToggleButton(isActive: appState.isDrawingMode) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.isDrawingMode.toggle()
                                if appState.isDrawingMode {
                                    appState.isGeometryModeEnabled = false
                                }
                            }
                        }
                        OptionMenuView()
                    }
                }
            }
        }
    }
    
    private func getBackgroundColor() -> Color {
        switch appState.appTheme {
        case .light:
            return Color.white
        case .dark:
            return Color(white: 0.05) // ほぼ黒
        case .blackboard:
            return Color(red: 0.0, green: 0.2, blue: 0.15) // 深みのあるチョークボード色
        }
    }
}

struct MovingPointOverlayView: View {
    @EnvironmentObject var appState: AppState

    private let pointColor = Color(red: 1.0, green: 0.2, blue: 0.7)

    var body: some View {
        GeometryReader { geometry in
            if appState.isMotionModeActive {
                let system = CoordinateSystem(
                    size: geometry.size,
                    zoomScale: appState.zoomScale,
                    panOffset: appState.panOffset
                )
                let t = appState.movingPointT
                let y = appState.parabola.evaluate(at: t)
                let point = system.screenPosition(mathX: t, mathY: y)
                let axisOrigin = system.screenPosition(mathX: 0, mathY: 0)

                ZStack {
                    Path { path in
                        path.move(to: point)
                        path.addLine(to: CGPoint(x: point.x, y: axisOrigin.y))
                    }
                    .stroke(
                        pointColor.opacity(0.85),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )

                    Path { path in
                        path.move(to: point)
                        path.addLine(to: CGPoint(x: axisOrigin.x, y: point.y))
                    }
                    .stroke(
                        pointColor.opacity(0.85),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )

                    Circle()
                        .fill(pointColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.95), lineWidth: 2)
                        )
                        .position(point)

                    Text(String(format: "(%.2f, %.2f)", t, y))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(pointColor.opacity(0.45), lineWidth: 1)
                        )
                        .position(x: point.x + 52, y: point.y - 22)
                }
                .animation(.easeInOut(duration: 0.12), value: appState.movingPointT)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ThemeMenuButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Menu {
            Button {
                appState.appTheme = .light
            } label: {
                Label("ライト", systemImage: "sun.max.fill")
            }
            Button {
                appState.appTheme = .dark
            } label: {
                Label("ダーク", systemImage: "moon.fill")
            }
            Button {
                appState.appTheme = .blackboard
            } label: {
                Label("黒板", systemImage: "graduationcap.fill")
            }
        } label: {
            ToolbarCircleIcon(systemName: themeIcon, tint: .primary)
        }
    }

    private var themeIcon: String {
        switch appState.appTheme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .blackboard: return "graduationcap.fill"
        }
    }
}

// MARK: - Share Button Component
struct ShareButton: View {
    var body: some View {
        Button(action: shareAction) {
            ToolbarCircleIcon(systemName: "square.and.arrow.up", tint: .primary)
        }
    }
    
    func shareAction() {
        // 現在のウィンドウを取得
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // スクリーンショットを撮影
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        
        // シェアシートを表示
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let rootVC = window.rootViewController {
            // iPad対応: ポップオーバーの位置設定
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: 50, y: 50, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}

struct QuizToggleButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ToolbarCircleIcon(systemName: "questionmark.circle", tint: isActive ? .orange : .primary)
        }
    }
}

struct DrawingToggleButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ToolbarCircleIcon(
                systemName: isActive ? "pencil.tip.crop.circle.badge.minus" : "pencil.tip.crop.circle.badge.plus",
                tint: isActive ? .green : .primary
            )
        }
    }
}

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isDrawingMode: Bool

    private let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isDrawingMode

        if isDrawingMode {
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        } else {
            toolPicker.setVisible(false, forFirstResponder: uiView)
            toolPicker.removeObserver(uiView)
            uiView.resignFirstResponder()
        }
    }
}

struct ToolbarCircleIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(tint)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(radius: 4)
    }
}
//
