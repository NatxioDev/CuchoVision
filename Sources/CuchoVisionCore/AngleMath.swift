import Foundation

/// Lleva un ángulo al rango (−π, π]. Sirve para que un giro que cruza
/// la costura de ±180° no se lea como una vuelta entera.
public func wrapToPi(_ angle: Double) -> Double {
    let twoPi = 2 * Double.pi
    var wrapped = angle.truncatingRemainder(dividingBy: twoPi)
    if wrapped > Double.pi {
        wrapped -= twoPi
    } else if wrapped <= -Double.pi {
        wrapped += twoPi
    }
    return wrapped
}
