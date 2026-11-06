import AppKit
import Foundation

/// Atajos globales. Hace falta Accesibilidad: si falta, el monitor global vuelve nil
/// y los botones del menú siguen funcionando.
final class HotkeyMonitor {
    static let recenterKeyCode: UInt16 = 15 // R
    static let pauseKeyCode: UInt16 = 35 // P

    var onRecenter: (() -> Void)?
    var onTogglePause: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private(set) var globalMonitorInstalled = false

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }
        let handler: (NSEvent) -> Void = { [weak self] event in
            self?.handle(event)
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: handler)
        globalMonitorInstalled = globalMonitor != nil
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
        globalMonitorInstalled = false
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting(.capsLock)
        guard flags == [.command, .option] else { return }
        switch event.keyCode {
        case Self.recenterKeyCode:
            onRecenter?()
        case Self.pauseKeyCode:
            onTogglePause?()
        default:
            break
        }
    }
}
