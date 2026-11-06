import Foundation

/// Filtro One Euro (Géry Casiez).
///
/// Deja pasar el movimiento lento y aplasta el temblor de alta frecuencia.
/// - `minCutoff`: corte mínimo en Hz. Más bajo = más suave y con más retraso.
/// - `beta`: cuánto sube el corte cuando la señal se acelera. Más alto = menos retraso en giros bruscos.
/// - `dCutoff`: corte del estimador de velocidad.
///
/// Ecuaciones del paper "1€ Filter: A Simple Speed-based Low-pass Filter".
public struct OneEuroFilter: Sendable {
    public var minCutoff: Double
    public var beta: Double
    public var dCutoff: Double

    private var filteredValue: Double?
    private var filteredDerivative: Double
    private var previousTimestamp: Double?

    public init(minCutoff: Double = 1.0, beta: Double = 0.0, dCutoff: Double = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
        self.filteredDerivative = 0
    }

    public mutating func reset() {
        filteredValue = nil
        filteredDerivative = 0
        previousTimestamp = nil
    }

    public mutating func filter(_ value: Double, timestamp: Double) -> Double {
        guard let previousTime = previousTimestamp, let previousValue = filteredValue else {
            filteredValue = value
            filteredDerivative = 0
            previousTimestamp = timestamp
            return value
        }

        // Un timestamp repetido o hacia atrás no debe disparar la derivada.
        guard timestamp > previousTime else {
            return previousValue
        }

        let dt = timestamp - previousTime
        let derivative = (value - previousValue) / dt
        let smoothedDerivative = exponentialSmoothing(
            derivative,
            previous: filteredDerivative,
            alpha: smoothingFactor(cutoff: dCutoff, dt: dt)
        )
        let cutoff = minCutoff + beta * abs(smoothedDerivative)
        let smoothed = exponentialSmoothing(
            value,
            previous: previousValue,
            alpha: smoothingFactor(cutoff: cutoff, dt: dt)
        )

        filteredValue = smoothed
        filteredDerivative = smoothedDerivative
        previousTimestamp = timestamp
        return smoothed
    }

    private func smoothingFactor(cutoff: Double, dt: Double) -> Double {
        let tau = 1.0 / (2.0 * Double.pi * max(cutoff, 1e-6))
        return 1.0 / (1.0 + tau / dt)
    }

    private func exponentialSmoothing(_ value: Double, previous: Double, alpha: Double) -> Double {
        let clamped = min(max(alpha, 0), 1)
        return clamped * value + (1 - clamped) * previous
    }
}
