import CoreGraphics
import Foundation

import CuchoVisionCore

/// Lee los monitores activos en el mismo espacio de coordenadas que el cursor (Quartz).
public enum ActiveDisplays {
    public static func bounds() -> [DisplayRect] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
            return []
        }

        var identifiers = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &identifiers, &count) == .success else {
            return []
        }

        return identifiers.prefix(Int(count)).map { identifier in
            let rect = CGDisplayBounds(identifier)
            return DisplayRect(
                x: Double(rect.origin.x),
                y: Double(rect.origin.y),
                width: Double(rect.size.width),
                height: Double(rect.size.height)
            )
        }
    }
}
