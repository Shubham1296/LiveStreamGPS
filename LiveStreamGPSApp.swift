//
// LiveStreamGPSApp.swift
// LiveStreamGPS
//

import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.landscapeRight

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

@main
struct LiveStreamGPSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ServerURLChanged"))) { _ in
                    // when URL changes: disconnect existing WS so user can reconnect
                    Task { @MainActor in
                        // intentionally empty: UI will call ws.connect when user taps record
                    }
                }
        }
    }
}

