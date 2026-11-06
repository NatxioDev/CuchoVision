import Foundation

/// Resultado de un frame: cuánto mover el cursor y qué ángulo quedó después del filtro.
public struct PointerStep: Equatable, Sendable {
    public var deltaX: Double
    public var deltaY: Double
    public var filteredYaw: Double
    public var filteredPitch: Double

    public init(deltaX: Double, deltaY: Double, filteredYaw: Double, filteredPitch: Double) {
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.filteredYaw = filteredYaw
        self.filteredPitch = filteredPitch
    }

    public static let zero = PointerStep(deltaX: 0, deltaY: 0, filteredYaw: 0, filteredPitch: 0)
}

/// Convierte yaw/pitch relativos a la pose de recentrado en un delta de cursor.
///
/// Es un control tipo joystick, no un mapa absoluto a la pantalla:
/// cabeza en el centro → cursor quieto; cabeza girada → el cursor se desplaza
/// mientras la cabeza siga ahí. Recentrar define un centro nuevo.
///
/// Orden: ángulo relativo → One Euro → zona muerta → aceleración → sensibilidad × dt.
/// El delta se multiplica por el tiempo entre muestras para que la velocidad no
/// dependa de si CoreMotion manda 60 Hz o 100 Hz. Un hueco largo se recorta
/// a 50 ms para que un tirón del sistema no dispare el cursor.
public struct PointerPipeline: Sendable {
    public static let maxFrameDelta = 0.05
    public static let defaultFrameDelta = 1.0 / 60.0

    public private(set) var settings: PointerSettings
    private var referenceYaw: Double?
    private var referencePitch: Double?
    private var lastTimestamp: Double?
    private var yawFilter: OneEuroFilter
    private var pitchFilter: OneEuroFilter

    public init(settings: PointerSettings = .default) {
        self.settings = settings
        self.yawFilter = Self.makeFilter(settings)
        self.pitchFilter = Self.makeFilter(settings)
    }

    public var hasReference: Bool {
        referenceYaw != nil && referencePitch != nil
    }

    public mutating func updateSettings(_ settings: PointerSettings) {
        self.settings = settings
        yawFilter.minCutoff = settings.minCutoff
        yawFilter.beta = settings.beta
        yawFilter.dCutoff = settings.derivativeCutoff
        pitchFilter.minCutoff = settings.minCutoff
        pitchFilter.beta = settings.beta
        pitchFilter.dCutoff = settings.derivativeCutoff
    }

    /// La próxima muestra pasa a ser el centro. No mueve el cursor por sí sola.
    public mutating func recenter(yaw: Double, pitch: Double) {
        referenceYaw = yaw
        referencePitch = pitch
        yawFilter.reset()
        pitchFilter.reset()
    }

    /// Olvida el centro. La próxima muestra que entre lo vuelve a fijar.
    public mutating func clearReference() {
        referenceYaw = nil
        referencePitch = nil
        yawFilter.reset()
        pitchFilter.reset()
    }

    public mutating func step(_ sample: HeadSample) -> PointerStep {
        let dt = advanceTime(to: sample.timestamp)
        guard let referenceYaw, let referencePitch else {
            recenter(yaw: sample.yaw, pitch: sample.pitch)
            return .zero
        }

        let relativeYaw = wrapToPi(sample.yaw - referenceYaw)
        let relativePitch = wrapToPi(sample.pitch - referencePitch)
        let filteredYaw = yawFilter.filter(relativeYaw, timestamp: sample.timestamp)
        let filteredPitch = pitchFilter.filter(relativePitch, timestamp: sample.timestamp)
        let zonedYaw = applyDeadZone(filteredYaw, zone: settings.deadZoneRadians)
        let zonedPitch = applyDeadZone(filteredPitch, zone: settings.deadZoneRadians)
        let acceleratedYaw = applyAcceleration(zonedYaw, factor: settings.acceleration)
        let acceleratedPitch = applyAcceleration(zonedPitch, factor: settings.acceleration)

        // Quartz mide Y hacia abajo. Pitch positivo (mirar arriba) tiene que restar Y,
        // salvo que el usuario invierta el eje en Ajustes.
        let xSign = settings.invertX ? -1.0 : 1.0
        let ySign = settings.invertY ? 1.0 : -1.0

        return PointerStep(
            deltaX: xSign * acceleratedYaw * settings.sensitivity * dt,
            deltaY: ySign * acceleratedPitch * settings.sensitivity * dt,
            filteredYaw: filteredYaw,
            filteredPitch: filteredPitch
        )
    }

    private mutating func advanceTime(to timestamp: Double) -> Double {
        let dt: Double
        if let lastTimestamp {
            let raw = timestamp - lastTimestamp
            dt = raw > 0 ? min(raw, Self.maxFrameDelta) : 0
        } else {
            dt = Self.defaultFrameDelta
        }
        lastTimestamp = timestamp
        return dt
    }

    private static func makeFilter(_ settings: PointerSettings) -> OneEuroFilter {
        OneEuroFilter(
            minCutoff: settings.minCutoff,
            beta: settings.beta,
            dCutoff: settings.derivativeCutoff
        )
    }
}
