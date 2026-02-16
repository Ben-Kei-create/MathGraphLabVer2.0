//
//  GraphLabView.swift
//  MathGraph Lab
//
//  Main workspace with banner ad at bottom
//

import SwiftUI

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
                    Text("MathGraph Lab")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                
                // シェアボタン + テーマ
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    ShareButton()
                    ThemeMenuButton()
                }
                
                // 右側ツールバー: ミッション + 設定
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // ミッションボタン
                    Button {
                        withAnimation {
                            if missionManager.isMissionActive {
                                missionManager.stop()
                            } else {
                                missionManager.start()
                            }
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(missionManager.isMissionActive ? .orange : .primary)
                    }
                    
                    // 設定メニュー
                    OptionMenuView()
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
            Image(systemName: themeIcon)
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
            Image(systemName: "square.and.arrow.up")
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
//
