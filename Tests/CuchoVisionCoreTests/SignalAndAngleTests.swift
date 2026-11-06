import XCTest
@testable import CuchoVisionCore

final class SignalConditioningTests: XCTestCase {
    func testDeadZoneSuppressesSmallValuesAndKeepsTheSign() {
        XCTAssertEqual(applyDeadZone(0.02, zone: 0.05), 0, accuracy: 1e-12)
        XCTAssertEqual(applyDeadZone(-0.02, zone: 0.05), 0, accuracy: 1e-12)
        XCTAssertEqual(applyDeadZone(0.08, zone: 0.05), 0.03, accuracy: 1e-12)
        XCTAssertEqual(applyDeadZone(-0.08, zone: 0.05), -0.03, accuracy: 1e-12)
    }

    func testDeadZoneTreatsNegativeThresholdAsZero() {
        XCTAssertEqual(applyDeadZone(-1.5, zone: -2), -1.5, accuracy: 1e-12)
    }

    func testAccelerationIsIdentityAtZeroAndGrowsWithMagnitude() {
        XCTAssertEqual(applyAcceleration(0.2, factor: 0), 0.2, accuracy: 1e-12)
        XCTAssertEqual(applyAcceleration(0.2, factor: -4), 0.2, accuracy: 1e-12)
        // gain = 1 + 4 * 0.2 = 1.8
        XCTAssertEqual(applyAcceleration(0.2, factor: 4), 0.36, accuracy: 1e-12)
        XCTAssertEqual(applyAcceleration(-0.2, factor: 4), -0.36, accuracy: 1e-12)
        XCTAssertGreaterThan(
            abs(applyAcceleration(0.5, factor: 4)),
            abs(applyAcceleration(0.2, factor: 4)) * (0.5 / 0.2)
        )
    }
}

final class AngleMathTests: XCTestCase {
    func testWrapKnownAngles() {
        XCTAssertEqual(wrapToPi(0), 0, accuracy: 1e-12)
        XCTAssertEqual(wrapToPi(.pi), .pi, accuracy: 1e-12)
        XCTAssertEqual(wrapToPi(-.pi), .pi, accuracy: 1e-9)
        XCTAssertEqual(wrapToPi(3 * .pi), .pi, accuracy: 1e-9)
        XCTAssertEqual(wrapToPi(-.pi / 2), -.pi / 2, accuracy: 1e-12)
    }

    func testWrapShortestPathAcrossTheBranchCut() {
        let wrapped = wrapToPi(-3 - 3)
        XCTAssertEqual(wrapped, -6 + 2 * .pi, accuracy: 1e-12)
        XCTAssertLessThan(abs(wrapped), 0.3)
    }
}
