import Foundation

/// Zona muerta alrededor del cero. Si la cabeza está casi quieta, el cursor no se mueve.
/// Fuera de la zona se resta el umbral para que no haya un salto al cruzarla.
public func applyDeadZone(_ value: Double, zone: Double) -> Double {
    let threshold = max(0, zone)
    let magnitude = abs(value)
    if magnitude <= threshold {
        return 0
    }
    return copysign(magnitude - threshold, value)
}

/// Aceleración: un giro chico mueve poco; un giro grande mueve más que la proporción lineal.
/// `factor` 0 deja el valor igual. El factor negativo se trata como 0.
public func applyAcceleration(_ value: Double, factor: Double) -> Double {
    let magnitude = abs(value)
    let gain = 1 + max(0, factor) * magnitude
    return value * gain
}
