import AppKit
import Combine
import Foundation
import os

import CuchoVisionCore
import CursorOutput
import HeadTracking

/// Une AirPods → filtro → cursor. Todo llega al hilo principal.
///
/// La primera pose (y cada recentrado o reanudación) es el centro: con la cabeza
/// ahí el cursor queda quieto. Girar la mantiene en movimiento, como un joystick.
final class AppModel: ObservableObject {
    @Published var isPaused = false
    @Published var connection: HeadphoneConnection = .unavailable
    @Published var accessibilityTrusted = false
    @Published var motionAuthorization: MotionAuthorization = .notDetermined
    @Published var globalHotkeysInstalled = false
    @Published var settings: PointerSettings
    @Published var hasReadout = false
    @Published var filteredYaw = 0.0
    @Published var filteredPitch = 0.0
    @Published var cursorX = 0.0
    @Published var cursorY = 0.0

    private let motion = HeadphoneMotionService()
    private let cursor = CursorMotion()
    private let hotkeys = HotkeyMonitor()
    private let logger = Logger(subsystem: "com.natxiodev.cuchovision", category: "app")
    private var pipeline: PointerPipeline
    private var lastSample: HeadSample?
    private var lastReadout = Date.distantPast
    private var lastTrustCheck = Date.distantPast
    private var didPromptAccessibility: Bool

    private static let promptKey = "cuchovision.didPromptAccessibility"

    init() {
        let loaded = PointerSettings.load()
        settings = loaded
        pipeline = PointerPipeline(settings: loaded)
        didPromptAccessibility = UserDefaults.standard.bool(forKey: Self.promptKey)

        motion.onSample = { [weak self] sample in
            self?.ingest(sample)
        }
        motion.onConnectionChange = { [weak self] connection in
            self?.handleConnection(connection)
        }
        hotkeys.onRecenter = { [weak self] in
            self?.recenter()
        }
        hotkeys.onTogglePause = { [weak self] in
            self?.togglePause()
        }

        connection = motion.probeConnection()
        motionAuthorization = motion.authorization
        hotkeys.start()
        globalHotkeysInstalled = hotkeys.globalMonitorInstalled
        refreshPermissions(promptIfNeeded: true)
        motion.start()
        logger.info("CuchoVision listo.")
    }

    deinit {
        motion.stop()
        hotkeys.stop()
    }

    var trackingText: String {
        if isPaused { return "Seguimiento: en pausa" }
        if !accessibilityTrusted { return "Seguimiento: falta Accesibilidad para mover el cursor" }
        if connection != .connected { return "Seguimiento: esperando AirPods" }
        return "Seguimiento: activo"
    }

    var airpodsText: String {
        switch connection {
        case .connected:
            return "AirPods: conectados"
        case .disconnected:
            return "AirPods: desconectados"
        case .unavailable:
            return "AirPods: no detectados"
        }
    }

    var accessibilityText: String {
        accessibilityTrusted ? "Accesibilidad: concedida" : "Accesibilidad: falta"
    }

    var motionPermissionText: String {
        switch motionAuthorization {
        case .authorized:
            return "Movimiento: permitido"
        case .notDetermined:
            return "Movimiento: todavía sin decidir"
        case .denied:
            return "Movimiento: denegado"
        case .restricted:
            return "Movimiento: restringido"
        case .unknown:
            return "Movimiento: estado desconocido"
        }
    }

    var hotkeyText: String {
        globalHotkeysInstalled
            ? "Atajos: ⌥⌘R recentra · ⌥⌘P pausa"
            : "Atajos globales: faltan (concedé Accesibilidad)"
    }

    func refreshPermissions(promptIfNeeded: Bool) {
        accessibilityTrusted = AccessibilityAccess.isTrusted(prompt: false)
        motionAuthorization = motion.authorization
        if promptIfNeeded, !accessibilityTrusted, !didPromptAccessibility {
            didPromptAccessibility = true
            UserDefaults.standard.set(true, forKey: Self.promptKey)
            accessibilityTrusted = AccessibilityAccess.isTrusted(prompt: true)
        }
        installHotkeysIfNeeded()
    }

    func requestAccessibility() {
        accessibilityTrusted = AccessibilityAccess.isTrusted(prompt: true)
        if !accessibilityTrusted {
            openAccessibilitySettings()
        }
        installHotkeysIfNeeded()
    }

    func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]
        for raw in candidates {
            guard let url = URL(string: raw) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    func openSettings() {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            motion.stop()
            logger.info("Seguimiento en pausa.")
        } else {
            // La cabeza se pudo mover durante la pausa: el próximo sample es el centro.
            pipeline.clearReference()
            motion.start()
            logger.info("Seguimiento reanudado.")
        }
    }

    func recenter() {
        if let lastSample {
            pipeline.recenter(yaw: lastSample.yaw, pitch: lastSample.pitch)
        } else {
            pipeline.clearReference()
        }
        logger.info("Pose recentrada.")
    }

    func updateSettings(_ newSettings: PointerSettings) {
        settings = newSettings
        pipeline.updateSettings(newSettings)
        newSettings.save()
    }

    func resetSettings() {
        updateSettings(.default)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func installHotkeysIfNeeded() {
        guard accessibilityTrusted, !globalHotkeysInstalled else { return }
        hotkeys.stop()
        hotkeys.start()
        globalHotkeysInstalled = hotkeys.globalMonitorInstalled
    }

    private func handleConnection(_ newValue: HeadphoneConnection) {
        connection = newValue
        guard newValue == .connected, !isPaused else { return }
        motion.start()
    }

    private func ingest(_ sample: HeadSample) {
        lastSample = sample
        let step = pipeline.step(sample)
        publishReadout(step)

        guard !isPaused else { return }
        if Date().timeIntervalSince(lastTrustCheck) > 1 {
            lastTrustCheck = Date()
            accessibilityTrusted = AccessibilityAccess.isTrusted(prompt: false)
            motionAuthorization = motion.authorization
        }
        guard accessibilityTrusted else { return }
        guard abs(step.deltaX) >= 0.15 || abs(step.deltaY) >= 0.15 else { return }
        cursor.apply(deltaX: step.deltaX, deltaY: step.deltaY)
    }

    private func publishReadout(_ step: PointerStep) {
        let now = Date()
        guard now.timeIntervalSince(lastReadout) > 0.2 else { return }
        lastReadout = now
        filteredYaw = step.filteredYaw
        filteredPitch = step.filteredPitch
        hasReadout = pipeline.hasReference
        if let location = cursor.location() {
            cursorX = location.x
            cursorY = location.y
        }
    }
}
