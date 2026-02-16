//
//  ControlPanelOverlay.swift
//  MathGraph Lab
//
//  右下コックピット: 設定ボタン＋コンパクトパネル（右手で操作しやすく・グラフを邪魔しない）
//

import SwiftUI

struct ControlPanelOverlay: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded: Bool = false
    /// スライダー操作中は true。指を離してから少し経つと false に戻す
    @State private var slidingEndTime: Date?
    @State private var motionTimer: Timer?
    @State private var isMotionPlaying: Bool = false
    @State private var isMotionSectionExpanded: Bool = false
    @State private var isLocusSectionExpanded: Bool = false
    @State private var isParabolaSectionExpanded: Bool = true
    @State private var isLineSectionExpanded: Bool = true

    private let motionRange: ClosedRange<Double> = -5.0...5.0
    private let motionStep: Double = 0.05
    private let motionInterval: TimeInterval = 1.0 / 60.0

    private var isSliding: Bool { slidingEndTime != nil }

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom) {
                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 12) {
                            // 1. 動点Pモード
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    CompactSectionHeader(symbol: "P(t)", color: .pink)
                                    if isMotionSectionExpanded {
                                        Button(action: toggleMotionPlayback) {
                                            HStack(spacing: 4) {
                                                Image(systemName: isMotionPlaying ? "stop.fill" : "play.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                Text(isMotionPlaying ? "停止" : "再生")
                                                    .font(.system(size: 11, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(isMotionPlaying ? Color.pink.opacity(0.75) : Color.pink)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Spacer(minLength: 4)
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if isMotionSectionExpanded {
                                                isMotionSectionExpanded = false
                                                appState.isMotionModeActive = false
                                            } else {
                                                isMotionSectionExpanded = true
                                                appState.isMotionModeActive = true
                                            }
                                        }
                                    } label: {
                                        Image(systemName: isMotionSectionExpanded ? "chevron.down.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.pink)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(Color.pink.opacity(0.15)))
                                    }
                                    .buttonStyle(.plain)
                                }

                                if isMotionSectionExpanded {

                                    HStack(spacing: 8) {
                                        Slider(
                                            value: Binding(
                                                get: { appState.movingPointT },
                                                set: { appState.movingPointT = min(max($0, motionRange.lowerBound), motionRange.upperBound) }
                                            ),
                                            in: motionRange
                                        )
                                        .tint(.pink)

                                        Text(String(format: "t=%.2f", appState.movingPointT))
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 56, alignment: .trailing)
                                    }
                                }
                            }

                            Divider()
                                .padding(.vertical, 2)

                            // 2. LOCUS（軌跡）
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    CompactSectionHeader(symbol: "LOCUS", color: .green)
                                    if isLocusSectionExpanded {
                                        let t = appState.movingPointT
                                        let py = appState.parabola.evaluate(at: t)
                                        let mx = (t + Double(appState.locusPointA.x)) / 2.0
                                        let my = (py + Double(appState.locusPointA.y)) / 2.0
                                        Text(String(format: "M(%.2f, %.2f)", mx, my))
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.green)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 4)
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if isLocusSectionExpanded {
                                                isLocusSectionExpanded = false
                                                appState.isLocusModeActive = false
                                            } else {
                                                isLocusSectionExpanded = true
                                                appState.isLocusModeActive = true
                                            }
                                        }
                                    } label: {
                                        Image(systemName: isLocusSectionExpanded ? "chevron.down.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.green)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(Color.green.opacity(0.15)))
                                    }
                                    .buttonStyle(.plain)
                                }

                                if isLocusSectionExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ParameterSliderWithIcon(
                                            icon: "arrow.left.and.right",
                                            value: Binding(
                                                get: { Double(appState.locusPointA.x) },
                                                set: { appState.updateLocusPointAX($0, snap: appState.isGridSnapEnabled) }
                                            ),
                                            range: -5...5,
                                            color: .green,
                                            compact: true
                                        )
                                        ParameterSliderWithIcon(
                                            icon: "arrow.up.and.down",
                                            value: Binding(
                                                get: { Double(appState.locusPointA.y) },
                                                set: { appState.updateLocusPointAY($0, snap: appState.isGridSnapEnabled) }
                                            ),
                                            range: -5...5,
                                            color: .green,
                                            compact: true
                                        )
                                    }
                                }
                            }

                            Divider()
                                .padding(.vertical, 2)

                            // 3. 放物線 f(x) = ax² + ...
                            HStack(spacing: 6) {
                                CompactSectionHeader(symbol: "ƒ(x)", color: .blue)
                                Spacer(minLength: 4)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isParabolaSectionExpanded.toggle()
                                    }
                                } label: {
                                    Image(systemName: isParabolaSectionExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.blue.opacity(0.15)))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        appState.showParabolaGraph.toggle()
                                    }
                                } label: {
                                    Image(systemName: appState.showParabolaGraph ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(appState.showParabolaGraph ? .blue : .secondary.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            if isParabolaSectionExpanded {
                                VStack(alignment: .leading, spacing: 6) {
                                    ParameterSliderWithIcon(
                                        icon: "plus.magnifyingglass",
                                        value: Binding(get: { appState.parabola.a }, set: { appState.updateParabolaA($0) }),
                                        range: -3...3,
                                        color: .blue,
                                        compact: true
                                    )
                                    ParameterSliderWithIcon(
                                        icon: "arrow.left.and.right",
                                        value: Binding(get: { appState.parabola.p }, set: { appState.updateParabolaP($0, snap: appState.isGridSnapEnabled) }),
                                        range: -5...5,
                                        color: .blue,
                                        compact: true
                                    )
                                    ParameterSliderWithIcon(
                                        icon: "arrow.up.and.down",
                                        value: Binding(get: { appState.parabola.q }, set: { appState.updateParabolaQ($0, snap: appState.isGridSnapEnabled) }),
                                        range: -5...5,
                                        color: .blue,
                                        compact: true
                                    )
                                }
                            }

                            Divider()
                                .padding(.vertical, 2)

                            // 4. 直線 ℓ(x) = mx + n
                            HStack(alignment: .center, spacing: 6) {
                                CompactSectionHeader(symbol: "ℓ(x)", color: .red)
                                if isLineSectionExpanded {
                                    // 2点を通る直線（アイコンのみ）
                                    if appState.markedPoints.count >= 2 {
                                        Button(action: applyLineFromLastTwoPoints) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 28, height: 28)
                                                .background(Circle().fill(Color.blue))
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    // 接線スナップ
                                    Button(action: applyTangentSnap) {
                                        Image(systemName: "line.diagonal")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.orange)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(Color.orange.opacity(0.15)))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(appState.parabola.a == 0 || !appState.showParabolaGraph)
                                    .opacity(appState.parabola.a == 0 || !appState.showParabolaGraph ? 0.35 : 1.0)

                                    // 面積モード
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            appState.isAreaModeEnabled.toggle()
                                        }
                                    } label: {
                                        Image(systemName: appState.isAreaModeEnabled ? "triangle.fill" : "triangle")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(appState.isAreaModeEnabled ? .green : .green.opacity(0.5))
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(appState.isAreaModeEnabled ? Color.green.opacity(0.18) : Color.green.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer(minLength: 4)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isLineSectionExpanded.toggle()
                                    }
                                } label: {
                                    Image(systemName: isLineSectionExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.red.opacity(0.15)))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        appState.showLinearGraph.toggle()
                                    }
                                } label: {
                                    Image(systemName: appState.showLinearGraph ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(appState.showLinearGraph ? .red : .secondary.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            if isLineSectionExpanded {
                                VStack(alignment: .leading, spacing: 6) {
                                    ParameterSliderWithIcon(
                                        icon: "skew",
                                        value: Binding(get: { appState.line.m }, set: { appState.updateLineM($0) }),
                                        range: -3...3,
                                        color: .red,
                                        compact: true
                                    )
                                    ParameterSliderWithIcon(
                                        icon: "distribute.vertical.center",
                                        value: Binding(get: { appState.line.n }, set: { appState.updateLineN($0) }),
                                        range: -5...5,
                                        color: .red,
                                        compact: true
                                    )
                                }
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(isSliding ? 0.06 : 0.12), radius: isSliding ? 4 : 8, x: 0, y: 4)
                        .frame(width: 260)
                        .opacity(isSliding ? 0.52 : 1.0) // スライダー操作中はグラフの並行移動がよく見えるよう透明に
                        .animation(.easeInOut(duration: 0.22), value: isSliding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    IconButton(
                        icon: "slider.horizontal.3",
                        color: isExpanded ? .blue.opacity(0.9) : .blue
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: appState.parabola.a) { _, _ in markSliding() }
        .onChange(of: appState.parabola.p) { _, _ in markSliding() }
        .onChange(of: appState.parabola.q) { _, _ in markSliding() }
        .onChange(of: appState.line.m) { _, _ in markSliding() }
        .onChange(of: appState.line.n) { _, _ in markSliding() }
        .onChange(of: appState.movingPointT) { _, _ in markSliding() }
        .onChange(of: appState.locusPointA) { _, _ in markSliding() }
        .onChange(of: appState.isMotionModeActive) { _, isActive in
            if !isActive {
                stopMotionPlayback()
                isMotionSectionExpanded = false
            }
        }
        .onChange(of: appState.isLocusModeActive) { _, isActive in
            if !isActive {
                isLocusSectionExpanded = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .graphTapped)) { _ in
            guard isExpanded else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = false
            }
        }
        .task(id: slidingEndTime) {
            guard let end = slidingEndTime else { return }
            try? await Task.sleep(nanoseconds: 450_000_000) // 0.45秒
            if slidingEndTime == end {
                slidingEndTime = nil
            }
        }
        .onDisappear {
            stopMotionPlayback()
        }
    }

    /// パラメータが触られたので「操作中」にし、0.45秒後に元に戻す
    private func markSliding() {
        slidingEndTime = Date().addingTimeInterval(0.45)
    }

    private func toggleMotionPlayback() {
        if isMotionPlaying {
            stopMotionPlayback()
            return
        }
        startMotionPlayback()
    }

    private func startMotionPlayback() {
        stopMotionPlayback()
        appState.isMotionModeActive = true
        appState.movingPointT = motionRange.lowerBound
        isMotionPlaying = true

        motionTimer = Timer.scheduledTimer(withTimeInterval: motionInterval, repeats: true) { _ in
            let next = appState.movingPointT + motionStep
            if next >= motionRange.upperBound {
                withAnimation(.linear(duration: motionInterval)) {
                    appState.movingPointT = motionRange.upperBound
                }
                stopMotionPlayback()
                return
            }
            withAnimation(.linear(duration: motionInterval)) {
                appState.movingPointT = next
            }
        }
    }

    private func stopMotionPlayback() {
        motionTimer?.invalidate()
        motionTimer = nil
        isMotionPlaying = false
    }

    /// 打った点の末尾2点を通る直線 y = mx + n を計算し、直線に適用する
    private func applyLineFromLastTwoPoints() {
        let points = appState.markedPoints
        guard points.count >= 2 else { return }

        let p1 = points[points.count - 2]
        let p2 = points[points.count - 1]
        let x1 = p1.x, y1 = p1.y
        let x2 = p2.x, y2 = p2.y

        guard abs(x2 - x1) > 1e-10 else {
            if appState.isHapticsEnabled {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            return
        }

        let m = (y2 - y1) / (x2 - x1)
        let n = y1 - m * x1

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            appState.updateLineM(m)
            appState.updateLineN(n)
            appState.isLineFromPoints = true
        }
        if appState.isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// 現在の傾き m を維持したまま、放物線に接する切片 n を逆算して適用する
    private func applyTangentSnap() {
        let a = appState.parabola.a
        guard abs(a) > 1e-10 else { return }

        let p = appState.parabola.p
        let q = appState.parabola.q
        let m = appState.line.m

        // 判別式 D=0 となる n を導出:
        // n = q + a*p² − (2ap + m)² / (4a)
        let n = q + a * p * p - pow(2.0 * a * p + m, 2) / (4.0 * a)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            appState.updateLineN(n)
        }
        if appState.isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
}

// MARK: - コンパクトセクションヘッダー（ƒ(x) / ℓ(x) スタイル）
private struct CompactSectionHeader: View {
    let symbol: String
    let color: Color

    var body: some View {
        Text(symbol)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}
