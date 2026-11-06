import XCTest
@testable import CuchoVisionCore

final class HeadPoseTests: XCTestCase {
    func testIdentityQuaternion() {
        let euler = HeadPose.yawPitchRoll(x: 0, y: 0, z: 0, w: 1)
        XCTAssertEqual(euler.yaw, 0, accuracy: 1e-12)
        XCTAssertEqual(euler.pitch, 0, accuracy: 1e-12)
        XCTAssertEqual(euler.roll, 0, accuracy: 1e-12)
    }

    func testZeroQuaternionReturnsZeros() {
        let euler = HeadPose.yawPitchRoll(x: 0, y: 0, z: 0, w: 0)
        XCTAssertEqual(euler.yaw, 0, accuracy: 1e-12)
        XCTAssertEqual(euler.pitch, 0, accuracy: 1e-12)
        XCTAssertEqual(euler.roll, 0, accuracy: 1e-12)
    }

    func testScaledQuaternionMatchesTheUnitQuaternion() {
        let unit = HeadPose.yawPitchRoll(x: 0, y: 0, z: sin(.pi / 4), w: cos(.pi / 4))
        let scaled = HeadPose.yawPitchRoll(x: 0, y: 0, z: 3 * sin(.pi / 4), w: 3 * cos(.pi / 4))
        XCTAssertEqual(scaled.yaw, unit.yaw, accuracy: 1e-12)
        XCTAssertEqual(scaled.pitch, unit.pitch, accuracy: 1e-12)
        XCTAssertEqual(scaled.roll, unit.roll, accuracy: 1e-12)
    }

    func testNinetyDegreeYawAboutZ() {
        let half = Double.pi / 4
        let euler = HeadPose.yawPitchRoll(x: 0, y: 0, z: sin(half), w: cos(half))
        XCTAssertEqual(euler.yaw, .pi / 2, accuracy: 1e-9)
        XCTAssertEqual(euler.pitch, 0, accuracy: 1e-9)
        XCTAssertEqual(euler.roll, 0, accuracy: 1e-9)
    }

    func testFortyFiveDegreeRotationsAboutEachAxis() {
        let half = Double.pi / 8
        let sine = sin(half)
        let cosine = cos(half)

        let pitch = HeadPose.yawPitchRoll(x: sine, y: 0, z: 0, w: cosine)
        XCTAssertEqual(pitch.pitch, .pi / 4, accuracy: 1e-9)
        XCTAssertEqual(pitch.yaw, 0, accuracy: 1e-9)
        XCTAssertEqual(pitch.roll, 0, accuracy: 1e-9)

        let yaw = HeadPose.yawPitchRoll(x: 0, y: 0, z: sine, w: cosine)
        XCTAssertEqual(yaw.yaw, .pi / 4, accuracy: 1e-9)
        XCTAssertEqual(yaw.pitch, 0, accuracy: 1e-9)
        XCTAssertEqual(yaw.roll, 0, accuracy: 1e-9)

        let roll = HeadPose.yawPitchRoll(x: 0, y: sine, z: 0, w: cosine)
        XCTAssertEqual(roll.roll, .pi / 4, accuracy: 1e-9)
        XCTAssertEqual(roll.pitch, 0, accuracy: 1e-9)
        XCTAssertEqual(roll.yaw, 0, accuracy: 1e-9)
    }
}
