import Foundation

/// Convierte el cuaternión de CoreMotion (x, y, z, w) en ángulos de Euler.
///
/// Convención usada (la misma que documenta `CMAttitude` para los ejes):
/// - yaw: giro sobre el eje vertical (izquierda / derecha)
/// - pitch: giro sobre el eje lateral (arriba / abajo)
/// - roll: inclinación
///
/// El cuaternión se normaliza. Si llega en cero, devolvemos ángulos en cero.
public enum HeadPose {
    public static func yawPitchRoll(
        x: Double,
        y: Double,
        z: Double,
        w: Double
    ) -> (yaw: Double, pitch: Double, roll: Double) {
        let norm = (x * x + y * y + z * z + w * w).squareRoot()
        guard norm > 1e-12 else {
            return (0, 0, 0)
        }

        let x = x / norm
        let y = y / norm
        let z = z / norm
        let w = w / norm

        let pitch = atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
        let rollSin = 2 * (w * y - z * x)
        let roll: Double
        if rollSin >= 1 {
            roll = Double.pi / 2
        } else if rollSin <= -1 {
            roll = -Double.pi / 2
        } else {
            roll = asin(rollSin)
        }
        let yaw = atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
        return (yaw, pitch, roll)
    }
}
