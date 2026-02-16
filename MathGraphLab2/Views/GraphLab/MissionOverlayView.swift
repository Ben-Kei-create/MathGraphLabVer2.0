//
//  MissionOverlayView.swift
//  MathGraph Lab
//
//  画面上部に表示するミッションカード: お題・現在値・クリア演出
//

import SwiftUI

struct MissionOverlayView: View {

    @EnvironmentObject var appState: AppState
    @ObservedObject var missionManager: MissionManager

    var body: some View {
        VStack {
            if missionManager.isMissionActive, let mission = missionManager.currentMission {
                missionCard(mission: mission)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: missionManager.isMissionActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: missionManager.isCleared)
    }

    // MARK: - Mission Card

    @ViewBuilder
    private func missionCard(mission: Mission) -> some View {
        VStack(spacing: 8) {
            if missionManager.isCleared {
                // クリア演出
                Text("CLEARED! 🎉")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                // タイトル
                Text(mission.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // 現在値 vs 目標値
                HStack(spacing: 12) {
                    ValuePill(
                        label: "現在",
                        value: missionManager.currentValueLabel(appState: appState),
                        color: .blue
                    )
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    ValuePill(
                        label: "目標",
                        value: mission.targetLabel,
                        color: .orange
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 280)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.top, 8)
        // パラメータ変更を監視してクリア判定
        .onChange(of: appState.parabola) { _, _ in checkClear() }
        .onChange(of: appState.line) { _, _ in checkClear() }
    }

    // MARK: - Clear Check

    private func checkClear() {
        guard missionManager.isMissionActive, !missionManager.isCleared else { return }

        if missionManager.checkMission(appState: appState) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                missionManager.isCleared = true
            }
            // 触覚フィードバック
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // 2秒後に次の問題
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    missionManager.nextMission()
                }
            }
        }
    }
}

// MARK: - Value Pill Component

private struct ValuePill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
