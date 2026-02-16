//
//  MissionManager.swift
//  MathGraph Lab
//
//  軽量クイズ（ミッション）モード: グラフ操作のお題を出し、数学的直感を養う
//

import SwiftUI
import Combine

// MARK: - Mission Type

enum MissionType: Equatable {
    /// 放物線と直線の三角形の面積を指定値にする
    case area(target: Double)
    /// 直線が指定座標を通るように m, n を調整する
    case passThrough(x: Double, y: Double)
    /// 放物線と直線を接する状態にする（D ≈ 0）
    case tangent
}

// MARK: - Mission

struct Mission: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: MissionType
    let tolerance: Double

    /// 目標値を表示用文字列で返す
    var targetLabel: String {
        switch type {
        case .area(let target):
            return String(format: "%.0f", target)
        case .passThrough(let x, let y):
            return "(\(Int(x)), \(Int(y)))"
        case .tangent:
            return "D = 0"
        }
    }
}

// MARK: - Preset Missions

private let presetMissions: [Mission] = [
    // 面積マスター系
    Mission(title: "面積を 6 にせよ！",
            description: "頂点と交点の三角形 S = 6",
            type: .area(target: 6),
            tolerance: 0.3),
    Mission(title: "面積を 12 にせよ！",
            description: "頂点と交点の三角形 S = 12",
            type: .area(target: 12),
            tolerance: 0.5),
    Mission(title: "面積を 18 にせよ！",
            description: "頂点と交点の三角形 S = 18",
            type: .area(target: 18),
            tolerance: 0.5),

    // 通る点系
    Mission(title: "点 (2, 4) を通せ！",
            description: "直線が (2, 4) を通るように調整",
            type: .passThrough(x: 2, y: 4),
            tolerance: 0.15),
    Mission(title: "点 (-1, 3) を通せ！",
            description: "直線が (-1, 3) を通るように調整",
            type: .passThrough(x: -1, y: 3),
            tolerance: 0.15),
    Mission(title: "点 (3, -2) を通せ！",
            description: "直線が (3, -2) を通るように調整",
            type: .passThrough(x: 3, y: -2),
            tolerance: 0.15),

    // 接線チャレンジ系
    Mission(title: "接線にせよ！",
            description: "放物線と直線を接する状態に",
            type: .tangent,
            tolerance: 0.2),
]

// MARK: - Mission Manager

final class MissionManager: ObservableObject {

    @Published var currentMission: Mission?
    @Published var isMissionActive: Bool = false
    @Published var isCleared: Bool = false

    private var usedIndices: Set<Int> = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public API

    /// ミッションモードを開始し、最初の問題を出題
    func start() {
        isMissionActive = true
        isCleared = false
        usedIndices.removeAll()
        nextMission()
    }

    /// ミッションモードを終了
    func stop() {
        isMissionActive = false
        currentMission = nil
        isCleared = false
    }

    /// 次のミッションを出題（重複なし、全部使い切ったらリセット）
    func nextMission() {
        isCleared = false

        if usedIndices.count >= presetMissions.count {
            usedIndices.removeAll()
        }

        let available = presetMissions.indices.filter { !usedIndices.contains($0) }
        guard let idx = available.randomElement() else { return }
        usedIndices.insert(idx)
        currentMission = presetMissions[idx]
    }

    /// 現在の AppState がクリア条件を満たしているか判定
    func checkMission(appState: AppState) -> Bool {
        guard let mission = currentMission else { return false }

        switch mission.type {
        case .area(let target):
            guard let area = currentAreaValue(appState: appState) else { return false }
            return abs(area - target) <= mission.tolerance

        case .passThrough(let tx, let ty):
            let lineY = appState.line.m * tx + appState.line.n
            let distance = abs(lineY - ty)
            return distance <= mission.tolerance

        case .tangent:
            let d = MathSolver.getDiscriminant(
                parabola: appState.parabola,
                line: appState.line
            )
            return abs(d) <= mission.tolerance
        }
    }

    /// UI 表示用: 現在値を返す
    func currentValueLabel(appState: AppState) -> String {
        guard let mission = currentMission else { return "—" }

        switch mission.type {
        case .area:
            guard let area = currentAreaValue(appState: appState) else { return "—" }
            return String(format: "%.2f", area)

        case .passThrough(let tx, _):
            let lineY = appState.line.m * tx + appState.line.n
            return String(format: "%.2f", lineY)

        case .tangent:
            let d = MathSolver.getDiscriminant(
                parabola: appState.parabola,
                line: appState.line
            )
            return String(format: "%.2f", d)
        }
    }

    // MARK: - Private

    /// 三角形面積（頂点 V(p,q) + 交点 A,B）を計算
    private func currentAreaValue(appState: AppState) -> Double? {
        let intersections = MathSolver.solveIntersections(
            parabola: appState.parabola,
            line: appState.line
        )
        guard intersections.count == 2 else { return nil }

        let vx = appState.parabola.p
        let vy = appState.parabola.q
        let ax = intersections[0].x, ay = intersections[0].y
        let bx = intersections[1].x, by = intersections[1].y

        return 0.5 * abs(ax * (by - vy) + bx * (vy - ay) + vx * (ay - by))
    }
}
