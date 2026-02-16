//
//  MathGraphLabApp.swift
//  MathGraph Lab
//
//  App entry point
//

import SwiftUI
import GoogleMobileAds

// MARK: - App Delegate for Orientation Lock
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct MathGraphLabApp: App {
    // AppDelegateを接続して画面回転を制御
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // IDD: アプリの状態を管理するオブジェクトを初期化
    @StateObject private var appState = AppState()
    
    // アプリ起動時の初期化処理
    init() {
        // エラー修正:
        // 旧: GADMobileAds.sharedInstance().start(completionHandler: nil)
        // 新: MobileAds.shared.start(completionHandler: nil)
        MobileAds.shared.start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            // メイン画面（GraphLabView）を表示
            GraphLabView()
                .environmentObject(appState)
        }
    }
}
