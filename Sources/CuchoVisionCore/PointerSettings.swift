import Foundation

/// Ajustes que convierten la pose de la cabeza en movimiento del cursor.
/// Se guardan en UserDefaults para que sobrevivan al cerrar la app.
public struct PointerSettings: Equatable, Sendable {
    /// Puntos de pantalla por radián por segundo. Más alto = más rápido.
    public var sensitivity: Double
    /// Radián. Dentro de este ángulo respecto del centro, el cursor queda quieto.
    public var deadZoneRadians: Double
    /// 0 = lineal. Más alto = los giros grandes corren mucho más que los chicos.
    public var acceleration: Double
    /// Corte mínimo del One Euro, en Hz.
    public var minCutoff: Double
    /// Respuesta del One Euro ante cambios bruscos.
    public var beta: Double
    /// Corte del estimador de velocidad del One Euro, en Hz.
    public var derivativeCutoff: Double
    /// Da vuelta izquierda/derecha.
    public var invertX: Bool
    /// Da vuelta arriba/abajo. Por defecto, mirar hacia arriba sube el cursor.
    public var invertY: Bool

    public init(
        sensitivity: Double,
        deadZoneRadians: Double,
        acceleration: Double,
        minCutoff: Double,
        beta: Double,
        derivativeCutoff: Double,
        invertX: Bool,
        invertY: Bool
    ) {
        self.sensitivity = sensitivity
        self.deadZoneRadians = deadZoneRadians
        self.acceleration = acceleration
        self.minCutoff = minCutoff
        self.beta = beta
        self.derivativeCutoff = derivativeCutoff
        self.invertX = invertX
        self.invertY = invertY
    }

    public static let `default` = PointerSettings(
        sensitivity: 1600,
        deadZoneRadians: 2.0 * .pi / 180.0,
        acceleration: 3.0,
        minCutoff: 1.0,
        beta: 0.05,
        derivativeCutoff: 1.0,
        invertX: false,
        invertY: false
    )

    public func save(to defaults: UserDefaults = .standard) {
        defaults.set(sensitivity, forKey: Key.sensitivity)
        defaults.set(deadZoneRadians, forKey: Key.deadZoneRadians)
        defaults.set(acceleration, forKey: Key.acceleration)
        defaults.set(minCutoff, forKey: Key.minCutoff)
        defaults.set(beta, forKey: Key.beta)
        defaults.set(derivativeCutoff, forKey: Key.derivativeCutoff)
        defaults.set(invertX, forKey: Key.invertX)
        defaults.set(invertY, forKey: Key.invertY)
    }

    public static func load(from defaults: UserDefaults = .standard) -> PointerSettings {
        let base = PointerSettings.default
        return PointerSettings(
            sensitivity: double(Key.sensitivity, base.sensitivity, defaults),
            deadZoneRadians: double(Key.deadZoneRadians, base.deadZoneRadians, defaults),
            acceleration: double(Key.acceleration, base.acceleration, defaults),
            minCutoff: double(Key.minCutoff, base.minCutoff, defaults),
            beta: double(Key.beta, base.beta, defaults),
            derivativeCutoff: double(Key.derivativeCutoff, base.derivativeCutoff, defaults),
            invertX: bool(Key.invertX, base.invertX, defaults),
            invertY: bool(Key.invertY, base.invertY, defaults)
        )
    }

    private static func double(_ key: String, _ fallback: Double, _ defaults: UserDefaults) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.double(forKey: key)
    }

    private static func bool(_ key: String, _ fallback: Bool, _ defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }

    private enum Key {
        static let sensitivity = "cuchovision.sensitivity"
        static let deadZoneRadians = "cuchovision.deadZoneRadians"
        static let acceleration = "cuchovision.acceleration"
        static let minCutoff = "cuchovision.minCutoff"
        static let beta = "cuchovision.beta"
        static let derivativeCutoff = "cuchovision.derivativeCutoff"
        static let invertX = "cuchovision.invertX"
        static let invertY = "cuchovision.invertY"
    }
}
