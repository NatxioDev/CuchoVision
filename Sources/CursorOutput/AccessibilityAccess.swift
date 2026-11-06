import ApplicationServices
import Foundation

/// Accesibilidad (TCC). Sin este permiso, `CGEvent` se descarta en silencio:
/// el cursor no se mueve y la API no devuelve un error.
public enum AccessibilityAccess {
    public static func isTrusted(prompt: Bool) -> Bool {
        guard prompt else {
            return AXIsProcessTrusted()
        }
        // Literal estable. El overlay de Swift cambió entre SDKs
        // (`CFString` vs `Unmanaged<CFString>`), y el valor de la clave no.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
