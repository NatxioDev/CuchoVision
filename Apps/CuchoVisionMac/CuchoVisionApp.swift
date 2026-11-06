import AppKit
import SwiftUI

@main
struct CuchoVisionApp: App {
    @StateObject private var model = AppModel()

    init() {
        // App de barra de menú: sin ícono en el Dock. También está en Info.plist (LSUIElement).
        NSApp.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
                .onAppear { model.refreshPermissions(promptIfNeeded: false) }
        } label: {
            Image(systemName: iconName)
                .accessibilityLabel("CuchoVision")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(model: model)
        }
    }

    private var iconName: String {
        if !model.accessibilityTrusted {
            return "exclamationmark.triangle"
        }
        if model.isPaused {
            return "pause.circle"
        }
        if model.connection == .connected {
            return "airpodspro"
        }
        return "headphones"
    }
}
