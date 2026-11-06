import CoreMotion
import Foundation
import os

import CuchoVisionCore

/// Estado de los AirPods respecto del head tracking.
public enum HeadphoneConnection: Equatable, Sendable {
    /// No hay auriculares compatibles conectados (o el sistema todavía no los anunció).
    case unavailable
    /// Había auriculares y se desconectaron o se guardaron en el estuche.
    case disconnected
    /// Hay un dispositivo que puede entregar `CMDeviceMotion`.
    case connected
}

/// Permiso de Motion & Fitness / movimiento de los AirPods.
public enum MotionAuthorization: Equatable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case unknown
}

/// Lee la pose de los AirPods con `CMHeadphoneMotionManager` y la entrega en el hilo principal.
///
/// `isDeviceMotionAvailable` no alcanza para saber si los buds están puestos:
/// el delegate avisa cuando se conectan o se van. La app tiene que llamar `start()`
/// de nuevo en cada conexión si el seguimiento no está en pausa.
///
/// Los callbacks se invocan en el main queue. Asignalos antes de `start()`.
public final class HeadphoneMotionService: NSObject, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {
    public var onSample: ((HeadSample) -> Void)?
    public var onConnectionChange: ((HeadphoneConnection) -> Void)?

    private let manager = CMHeadphoneMotionManager()
    private let logger = Logger(subsystem: "com.natxiodev.cuchovision", category: "head-tracking")
    private var didLogStreamError = false

    public override init() {
        super.init()
        manager.delegate = self
    }

    deinit {
        if manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
    }

    public var authorization: MotionAuthorization {
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .unknown
        }
    }

    /// Mejor estimación sin esperar un evento del delegate.
    public func probeConnection() -> HeadphoneConnection {
        if manager.isDeviceMotionActive || manager.isDeviceMotionAvailable {
            return .connected
        }
        return .unavailable
    }

    public func start() {
        guard manager.isDeviceMotionAvailable else {
            logger.debug("Head tracking no disponible: no hay AirPods compatibles conectados.")
            return
        }
        guard !manager.isDeviceMotionActive else { return }

        didLogStreamError = false
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            if error != nil {
                if !self.didLogStreamError {
                    self.didLogStreamError = true
                    self.logger.error("Falló el stream de movimiento de los AirPods.")
                }
                return
            }
            guard let motion else { return }
            // yaw/pitch/roll de CMAttitude ya están en el marco de CoreMotion.
            // HeadPose queda en Core para tests y para un cuaternión suelto.
            let attitude = motion.attitude
            let sample = HeadSample(
                yaw: attitude.yaw,
                pitch: attitude.pitch,
                roll: attitude.roll,
                timestamp: motion.timestamp
            )
            self.deliverSample(sample)
        }
    }

    public func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
    }

    @objc public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        performOnMain { [weak self] in
            self?.logger.info("AirPods conectados.")
            self?.deliverConnection(.connected)
        }
    }

    @objc public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        performOnMain { [weak self] in
            self?.logger.info("AirPods desconectados.")
            self?.stop()
            self?.deliverConnection(.disconnected)
        }
    }

    private func performOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func deliverSample(_ sample: HeadSample) {
        let notify = { self.onSample?(sample) }
        if Thread.isMainThread {
            notify()
        } else {
            DispatchQueue.main.async(execute: notify)
        }
    }

    private func deliverConnection(_ connection: HeadphoneConnection) {
        let notify = { self.onConnectionChange?(connection) }
        if Thread.isMainThread {
            notify()
        } else {
            DispatchQueue.main.async(execute: notify)
        }
    }
}
