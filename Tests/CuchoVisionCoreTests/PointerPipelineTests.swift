import XCTest
@testable import CuchoVisionCore

final class PointerPipelineTests: XCTestCase {
    private func linearSettings() -> PointerSettings {
        PointerSettings(
            sensitivity: 60,
            deadZoneRadians: 0,
            acceleration: 0,
            minCutoff: 1,
            beta: 0,
            derivativeCutoff: 1,
            invertX: false,
            invertY: false
        )
    }

    /// La primera muestra fija el centro. `sensitivity` 60 y dt = 1/60 hacen
    /// que el delta sea igual al ángulo ya acondicionado.
    private func move(
        settings: PointerSettings,
        yaw: Double,
        pitch: Double = 0,
        secondTimestamp: Double = 1.0 / 60.0
    ) -> PointerStep {
        var pipeline = PointerPipeline(settings: settings)
        _ = pipeline.step(HeadSample(yaw: 0, pitch: 0, timestamp: 0))
        return pipeline.step(HeadSample(yaw: yaw, pitch: pitch, timestamp: secondTimestamp))
    }

    func testFirstSampleRecentersAndDoesNotMove() {
        var pipeline = PointerPipeline(settings: linearSettings())
        XCTAssertFalse(pipeline.hasReference)
        let step = pipeline.step(HeadSample(yaw: 0.4, pitch: -0.2, timestamp: 1))
        XCTAssertEqual(step, .zero)
        XCTAssertTrue(pipeline.hasReference)
    }

    func testPositiveYawMovesRightAndPositivePitchMovesUp() {
        let step = move(settings: linearSettings(), yaw: 0.2, pitch: 0.1)
        XCTAssertEqual(step.deltaX, 0.2, accuracy: 1e-9)
        // Y de Quartz crece hacia abajo, así que mirar arriba resta.
        XCTAssertEqual(step.deltaY, -0.1, accuracy: 1e-9)
        XCTAssertEqual(step.filteredYaw, 0.2, accuracy: 1e-9)
        XCTAssertEqual(step.filteredPitch, 0.1, accuracy: 1e-9)
    }

    func testDeadZoneBlocksSmallOffsets() {
        var settings = linearSettings()
        settings.deadZoneRadians = 0.05
        let inside = move(settings: settings, yaw: 0.04, pitch: -0.01)
        XCTAssertEqual(inside.deltaX, 0, accuracy: 1e-12)
        XCTAssertEqual(inside.deltaY, 0, accuracy: 1e-12)

        let outside = move(settings: settings, yaw: 0.08)
        XCTAssertEqual(outside.deltaX, 0.03, accuracy: 1e-9)
    }

    func testAccelerationScalesLargeOffsetsMore() {
        var settings = linearSettings()
        settings.acceleration = 4
        let step = move(settings: settings, yaw: 0.1)
        // 0.1 * (1 + 4 * 0.1) = 0.14
        XCTAssertEqual(step.deltaX, 0.14, accuracy: 1e-9)
    }

    func testDeadZoneThenAcceleration() {
        var settings = linearSettings()
        settings.deadZoneRadians = 0.04
        settings.acceleration = 10
        let step = move(settings: settings, yaw: 0.10)
        // zona: 0.06; gain = 1 + 10 * 0.06 = 1.6; delta = 0.096
        XCTAssertEqual(step.deltaX, 0.096, accuracy: 1e-9)
    }

    func testInvertFlagsFlipAxes() {
        var settings = linearSettings()
        settings.invertX = true
        settings.invertY = true
        let step = move(settings: settings, yaw: 0.2, pitch: 0.1)
        XCTAssertEqual(step.deltaX, -0.2, accuracy: 1e-9)
        XCTAssertEqual(step.deltaY, 0.1, accuracy: 1e-9)
    }

    func testDeltaScalesWithCappedFrameTime() {
        var settings = linearSettings()
        settings.sensitivity = 100
        let step = move(settings: settings, yaw: 0.2, secondTimestamp: 10)
        XCTAssertEqual(step.deltaX, 0.2 * 100 * PointerPipeline.maxFrameDelta, accuracy: 1e-9)
    }

    func testHoldingTheCenterProducesNoDelta() {
        var pipeline = PointerPipeline(settings: linearSettings())
        _ = pipeline.step(HeadSample(yaw: 1.2, pitch: -0.4, timestamp: 0))
        let step = pipeline.step(HeadSample(yaw: 1.2, pitch: -0.4, timestamp: 1.0 / 60.0))
        XCTAssertEqual(step.deltaX, 0, accuracy: 1e-9)
        XCTAssertEqual(step.deltaY, 0, accuracy: 1e-9)
    }

    func testRecenterMakesTheCurrentPoseTheNewZero() {
        var pipeline = PointerPipeline(settings: linearSettings())
        _ = pipeline.step(HeadSample(yaw: 0, pitch: 0, timestamp: 0))
        let before = pipeline.step(HeadSample(yaw: 0.3, pitch: 0, timestamp: 1.0 / 60.0))
        XCTAssertGreaterThan(before.deltaX, 0)

        pipeline.recenter(yaw: 0.3, pitch: 0)
        let after = pipeline.step(HeadSample(yaw: 0.3, pitch: 0, timestamp: 2.0 / 60.0))
        XCTAssertEqual(after.deltaX, 0, accuracy: 1e-9)
        XCTAssertEqual(after.deltaY, 0, accuracy: 1e-9)
    }

    func testYawWrapsAcrossTheBranchCut() {
        var pipeline = PointerPipeline(settings: linearSettings())
        _ = pipeline.step(HeadSample(yaw: 3, pitch: 0, timestamp: 0))
        let step = pipeline.step(HeadSample(yaw: -3, pitch: 0, timestamp: 1.0 / 60.0))
        XCTAssertEqual(step.deltaX, -6 + 2 * .pi, accuracy: 1e-9)
        XCTAssertLessThan(abs(step.deltaX), 0.3)
    }

    func testClearReferenceRecentersOnTheNextSample() {
        var pipeline = PointerPipeline(settings: linearSettings())
        _ = pipeline.step(HeadSample(yaw: 0, pitch: 0, timestamp: 0))
        pipeline.clearReference()
        let armed = pipeline.step(HeadSample(yaw: 0.5, pitch: 0.2, timestamp: 1))
        XCTAssertEqual(armed, .zero)
        let held = pipeline.step(HeadSample(yaw: 0.5, pitch: 0.2, timestamp: 1 + 1.0 / 60.0))
        XCTAssertEqual(held.deltaX, 0, accuracy: 1e-9)
        XCTAssertEqual(held.deltaY, 0, accuracy: 1e-9)
    }

    func testNoiseInsideTheDeadZoneStaysStill() {
        var settings = linearSettings()
        settings.deadZoneRadians = 0.03
        settings.minCutoff = 1
        var pipeline = PointerPipeline(settings: settings)
        _ = pipeline.step(HeadSample(yaw: 0, pitch: 0, timestamp: 0))
        var timestamp = 0.0
        for index in 0..<40 {
            timestamp += 1.0 / 60.0
            let jitter = index.isMultiple(of: 2) ? 0.01 : -0.01
            let step = pipeline.step(HeadSample(yaw: jitter, pitch: jitter, timestamp: timestamp))
            XCTAssertEqual(step.deltaX, 0, accuracy: 1e-9)
            XCTAssertEqual(step.deltaY, 0, accuracy: 1e-9)
        }
    }
}

final class PointerSettingsTests: XCTestCase {
    func testRoundTripThroughUserDefaults() {
        let suiteName = "CuchoVisionPointerSettingsTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var settings = PointerSettings.default
        settings.sensitivity = 1234
        settings.deadZoneRadians = 0.07
        settings.acceleration = 6
        settings.minCutoff = 2.5
        settings.beta = 0.4
        settings.derivativeCutoff = 1.7
        settings.invertX = true
        settings.invertY = true
        settings.save(to: defaults)

        let loaded = PointerSettings.load(from: defaults)
        XCTAssertEqual(loaded, settings)

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testMissingKeysUseDefaults() {
        let suiteName = "CuchoVisionPointerSettingsEmpty"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        XCTAssertEqual(PointerSettings.load(from: defaults), .default)
        defaults.removePersistentDomain(forName: suiteName)
    }
}
