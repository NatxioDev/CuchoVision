import HeadTracking
import CursorOutput
import XCTest

/// No mueve el cursor ni muestra diálogos. Solo comprueba que los módulos
/// de sistema linkean y que consultar el permiso sin `prompt` no revienta.
final class ModuleSmokeTests: XCTestCase {
    func testConnectionCasesDiffer() {
        XCTAssertNotEqual(HeadphoneConnection.connected, HeadphoneConnection.disconnected)
        XCTAssertNotEqual(HeadphoneConnection.connected, HeadphoneConnection.unavailable)
        XCTAssertEqual(MotionAuthorization.authorized, .authorized)
    }

    func testQueryingTrustAndDisplaysDoesNotPrompt() {
        // Sin prompt: no abre diálogos. Tampoco movemos el cursor.
        _ = AccessibilityAccess.isTrusted(prompt: false)
        _ = ActiveDisplays.bounds()
        _ = QuartzCursorController.self
    }
}
