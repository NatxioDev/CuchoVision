import XCTest
@testable import CuchoVisionCore

final class DisplayLayoutTests: XCTestCase {
    func testEmptyLayoutLeavesThePointAlone() {
        let layout = DisplayLayout(displays: [])
        XCTAssertNil(layout.unionBounds)
        let point = layout.clamp(x: 12, y: -4)
        XCTAssertEqual(point.x, 12, accuracy: 1e-12)
        XCTAssertEqual(point.y, -4, accuracy: 1e-12)
    }

    func testSingleDisplayClampsOutsidePoints() {
        let layout = DisplayLayout(displays: [
            DisplayRect(x: 0, y: 0, width: 1000, height: 800)
        ])
        let inside = layout.clamp(x: 10, y: 20)
        XCTAssertEqual(inside.x, 10, accuracy: 1e-12)
        XCTAssertEqual(inside.y, 20, accuracy: 1e-12)

        let outside = layout.clamp(x: -50, y: 5000)
        XCTAssertEqual(outside.x, 0, accuracy: 1e-12)
        XCTAssertEqual(outside.y, 799, accuracy: 1e-12)
    }

    func testSideBySideDisplaysUseTheUnion() throws {
        let layout = DisplayLayout(displays: [
            DisplayRect(x: 0, y: 0, width: 1440, height: 900),
            DisplayRect(x: 1440, y: 0, width: 1920, height: 1080)
        ])
        let bounds = try XCTUnwrap(layout.unionBounds)
        XCTAssertEqual(bounds.x, 0, accuracy: 1e-12)
        XCTAssertEqual(bounds.y, 0, accuracy: 1e-12)
        XCTAssertEqual(bounds.width, 3360, accuracy: 1e-12)
        XCTAssertEqual(bounds.height, 1080, accuracy: 1e-12)

        let crossing = layout.clamp(x: 2000, y: 100)
        XCTAssertEqual(crossing.x, 2000, accuracy: 1e-12)
        XCTAssertEqual(crossing.y, 100, accuracy: 1e-12)

        let pastTheRightEdge = layout.clamp(x: 9000, y: -20)
        XCTAssertEqual(pastTheRightEdge.x, 3359, accuracy: 1e-12)
        XCTAssertEqual(pastTheRightEdge.y, 0, accuracy: 1e-12)
    }

    func testNegativeOriginsForDisplaysLeftAndAbove() throws {
        // El de la izquierda arranca 200 puntos arriba del principal y termina más abajo.
        let layout = DisplayLayout(displays: [
            DisplayRect(x: 0, y: 0, width: 1440, height: 900),
            DisplayRect(x: -1920, y: -200, width: 1920, height: 1200)
        ])
        let bounds = try XCTUnwrap(layout.unionBounds)
        XCTAssertEqual(bounds.x, -1920, accuracy: 1e-12)
        XCTAssertEqual(bounds.y, -200, accuracy: 1e-12)
        XCTAssertEqual(bounds.width, 3360, accuracy: 1e-12)
        XCTAssertEqual(bounds.height, 1200, accuracy: 1e-12)

        let onTheLeftScreen = layout.clamp(x: -100, y: 40)
        XCTAssertEqual(onTheLeftScreen.x, -100, accuracy: 1e-12)
        XCTAssertEqual(onTheLeftScreen.y, 40, accuracy: 1e-12)

        let beyond = layout.clamp(x: -5000, y: -5000)
        XCTAssertEqual(beyond.x, -1920, accuracy: 1e-12)
        XCTAssertEqual(beyond.y, -200, accuracy: 1e-12)
    }

    func testGapInsideTheUnionIsKept() {
        // El monitor principal es más bajo. El punto queda "arriba" de él,
        // en un hueco, pero adentro del rectángulo unión. El recorte no lo mueve.
        let layout = DisplayLayout(displays: [
            DisplayRect(x: 0, y: 0, width: 1000, height: 500),
            DisplayRect(x: 1000, y: -200, width: 800, height: 1000)
        ])
        let gap = layout.clamp(x: 500, y: -100)
        XCTAssertEqual(gap.x, 500, accuracy: 1e-12)
        XCTAssertEqual(gap.y, -100, accuracy: 1e-12)
    }
}
