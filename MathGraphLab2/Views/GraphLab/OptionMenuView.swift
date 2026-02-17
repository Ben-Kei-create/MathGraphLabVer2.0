//
//  OptionMenuView.swift
//  MathGraph Lab
//
//  右上メニュー: 教育的機能（面積・作図・距離）とツール・システム設定
//  「数学探究ツール」として、必要な時だけ機能を選べる Less is More 設計
//

import SwiftUI

struct OptionMenuView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Menu {
            // MARK: - 操作・ツール (Tools)
            Section {
                Toggle(isOn: $appState.isGridSnapEnabled) {
                    Label("グリッドにスナップ", systemImage: "grid")
                }

                Toggle(isOn: $appState.isHapticsEnabled) {
                    Label("触覚フィードバック", systemImage: "hand.tap")
                }
            } header: {
                Text("操作・ツール")
            }

            // MARK: - システム (System)
            Section {
                Link(destination: URL(string: "https://your-site.com/privacy")!) {
                    Label("プライバシーポリシー", systemImage: "doc.text")
                }
            } header: {
                Text("システム")
            }

            Divider()

            Section {
                Button(role: .destructive, action: {
                    withAnimation {
                        appState.reset()
                    }
                }) {
                    Label("グラフを初期状態に戻す", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

#Preview {
    OptionMenuView()
        .environmentObject(AppState())
}
