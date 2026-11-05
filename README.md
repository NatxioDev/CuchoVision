# CuchoVision

**Control your Mac's cursor with your head, your eyes and your Apple Watch.**
*Controla el cursor de tu Mac con la cabeza, la mirada y tu Apple Watch.*

> 🚧 Early stage. Only the idea and roadmap live here for now. Contributions and ideas welcome!

## What is it?

CuchoVision turns the hardware you already own into a hands-free mouse for macOS. It works in **levels**: each one adds precision and features, and each one activates only if you have the hardware.

| Level | Hardware | What it adds |
|---|---|---|
| **1 – Head** (core) | AirPods with head tracking | Move the cursor by turning your head, with smoothing, magnetic snapping to buttons and dwell click. Works on its own. |
| **2 – Eyes** | Mac camera | Eye tracking jumps the cursor to where you look; your head fine-tunes it. |
| **3 – Watch** | Apple Watch | Clicks and gestures: double tap / pinch, right click, scroll, drag. |

## Features (planned)

- 🎧 **Head tracking** via `CMHeadphoneMotionManager` (AirPods), cursor moved with `CGEvent`.
- 👀 **Eye tracking** with the Mac camera (Vision / MediaPipe iris) and a 9-point calibration.
- 🧈 **Smoothing**: One Euro Filter, dead zone, acceleration and a recenter gesture.
- 🧲 **Magnetic snapping** to buttons using the macOS Accessibility API.
- ⏱️ **Dwell click**: hold still over something to click it.
- ⌚ **Apple Watch gestures**: click, right click, scroll and drag, sent to the Mac over Bluetooth / local network.
- ⌨️ **Auto-pause while typing**: control pauses when a text field gets focus and resumes when you leave it.
- 🖥️ **Multi-display**: your head picks the screen, your eyes refine on the main one.
- 📍 **Menu bar app** to toggle, recalibrate and tune sensitivity.

## Tech stack

- Swift, SwiftUI
- macOS app + watchOS app
- CoreMotion, Vision / MediaPipe, Accessibility (AX) API, WatchConnectivity / Network framework

## Roadmap

- [ ] Level 1: AirPods head tracking moves the cursor
- [ ] Smoothing + recenter
- [ ] Dwell click + magnetic snapping
- [ ] Auto-pause while typing
- [ ] Menu bar app
- [ ] Level 2: eye tracking + calibration
- [ ] Multi-display support
- [ ] Level 3: Apple Watch companion app

## Privacy

Everything runs locally on your Mac and Watch. No camera frames or motion data leave your devices.

## Contributing

Ideas, issues and PRs are welcome. Open an issue to start a discussion.

## License

[MIT](LICENSE) © Ignacio Paz
