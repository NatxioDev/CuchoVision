import Foundation

/// Una muestra de la pose de la cabeza, en radianes, con el reloj de CoreMotion.
public struct HeadSample: Equatable, Sendable {
    public var yaw: Double
    public var pitch: Double
    public var roll: Double
    public var timestamp: TimeInterval

    public init(yaw: Double, pitch: Double, roll: Double = 0, timestamp: TimeInterval) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
        self.timestamp = timestamp
    }
}
