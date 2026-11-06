import CoreGraphics
import Foundation

import CuchoVisionCore

/// Publica un `mouseMoved` con `CGEvent`. Hace falta el permiso de Accesibilidad;
/// si falta, el sistema tira el evento y esta función no se entera.
public struct QuartzCursorController: Sendable {
    public init() {}

    public func location() -> (x: Double, y: Double)? {
        guard let event = CGEvent(source: nil) else { return nil }
        return (Double(event.location.x), Double(event.location.y))
    }

    public func move(toX x: Double, y: Double) {
        let point = CGPoint(x: x, y: y)
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        event.post(tap: .cghidEventTap)
    }
}

/// Aplica un delta al cursor y lo recorta a la unión de los monitores.
/// Vuelve a leer las pantallas como mucho cada medio segundo.
public final class CursorMotion: @unchecked Sendable {
    private let cursor = QuartzCursorController()
    private var cached = DisplayLayout(displays: [])
    private var lastFetch = Date.distantPast

    public init() {}

    public func apply(deltaX: Double, deltaY: Double) {
        guard let current = cursor.location() else { return }
        let layout = layout()
        let clamped = layout.clamp(x: current.x + deltaX, y: current.y + deltaY)
        cursor.move(toX: clamped.x, y: clamped.y)
    }

    public func location() -> (x: Double, y: Double)? {
        cursor.location()
    }

    private func layout() -> DisplayLayout {
        let stale = Date().timeIntervalSince(lastFetch) > 0.5
        if stale || cached.displays.isEmpty {
            let fresh = DisplayLayout(displays: ActiveDisplays.bounds())
            if !fresh.displays.isEmpty {
                cached = fresh
                lastFetch = Date()
            }
        }
        return cached
    }
}
