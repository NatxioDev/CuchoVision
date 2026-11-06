import Foundation

/// Un monitor en coordenadas globales de Quartz (origen arriba a la izquierda, Y hacia abajo).
/// Es el mismo espacio que usa `CGEvent` para el cursor.
public struct DisplayRect: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
}

/// Unión de todos los monitores. El cursor se recorta a ese rectángulo,
/// así puede cruzar de una pantalla a la otra y no se pierde afuera.
public struct DisplayLayout: Equatable, Sendable {
    public var displays: [DisplayRect]

    public init(displays: [DisplayRect]) {
        self.displays = displays
    }

    /// Rectángulo que envuelve todas las pantallas, incluidos los orígenes negativos
    /// (monitor a la izquierda o arriba del principal).
    public var unionBounds: DisplayRect? {
        guard var accumulator = displays.first else { return nil }
        for display in displays.dropFirst() {
            let minX = min(accumulator.minX, display.minX)
            let minY = min(accumulator.minY, display.minY)
            let maxX = max(accumulator.maxX, display.maxX)
            let maxY = max(accumulator.maxY, display.maxY)
            accumulator = DisplayRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        }
        return accumulator
    }

    /// Recorta un punto al rectángulo unión. Si no hay pantallas, el punto no se toca.
    /// Se deja 1 punto de margen interior para que el cursor siga sobre un píxel visible.
    public func clamp(x: Double, y: Double) -> (x: Double, y: Double) {
        guard let bounds = unionBounds, bounds.width > 0, bounds.height > 0 else {
            return (x, y)
        }
        let inset = 1.0
        let maxX = bounds.width > inset ? bounds.maxX - inset : bounds.minX
        let maxY = bounds.height > inset ? bounds.maxY - inset : bounds.minY
        return (
            min(max(x, bounds.minX), maxX),
            min(max(y, bounds.minY), maxY)
        )
    }
}
