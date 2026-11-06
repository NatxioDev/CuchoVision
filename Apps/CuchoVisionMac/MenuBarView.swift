import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Text(model.trackingText)
        Text(model.airpodsText)
        Text(model.accessibilityText)
        Text(model.motionPermissionText)
        Text(model.hotkeyText)
        Divider()
        Button(model.isPaused ? "Reanudar (⌥⌘P)" : "Pausar (⌥⌘P)") {
            model.togglePause()
        }
        Button("Recentrar (⌥⌘R)") {
            model.recenter()
        }
        Divider()
        if !model.accessibilityTrusted {
            Button("Pedir permiso de Accesibilidad") {
                model.requestAccessibility()
            }
            Button("Abrir Ajustes del Sistema") {
                model.openAccessibilitySettings()
            }
        }
        Button("Ajustes…") {
            model.openSettings()
        }
        Divider()
        Button("Salir de CuchoVision") {
            model.quit()
        }
    }
}
