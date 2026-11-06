import SwiftUI

import CuchoVisionCore
import HeadTracking

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            Form {
                Section {
                    LabeledContent("Seguimiento", value: model.isPaused ? "En pausa" : "Activo")
                    LabeledContent("AirPods") {
                        Text(model.connectionLabel)
                    }
                    if model.hasReadout {
                        LabeledContent("Yaw", value: degrees(model.filteredYaw))
                        LabeledContent("Pitch", value: degrees(model.filteredPitch))
                    } else {
                        LabeledContent("Pose", value: "Todavía sin datos")
                    }
                    LabeledContent(
                        "Cursor",
                        value: String(format: "%.0f, %.0f", model.cursorX, model.cursorY)
                    )
                } header: {
                    Text("Ahora")
                } footer: {
                    Text("Mirá al frente y tocá Recentrar. El número de yaw cambia cuando girás la cabeza a los costados; el de pitch, cuando mirás arriba o abajo.")
                }

                Section {
                    slider(
                        title: "Velocidad",
                        value: setting(\.sensitivity),
                        range: 200...4000,
                        label: String(format: "%.0f", model.settings.sensitivity)
                    )
                    slider(
                        title: "Zona muerta",
                        value: deadZoneDegrees,
                        range: 0...8,
                        label: String(format: "%.1f°", deadZoneDegrees.wrappedValue)
                    )
                    slider(
                        title: "Aceleración",
                        value: setting(\.acceleration),
                        range: 0...8,
                        label: String(format: "%.1f", model.settings.acceleration)
                    )
                } header: {
                    Text("Puntero")
                } footer: {
                    Text("Zona muerta: cuánto podés mover la cabeza sin que el cursor se vaya. Aceleración: un giro grande corre más que uno chico.")
                }

                Section {
                    Toggle("Invertir horizontal", isOn: setting(\.invertX))
                    Toggle("Invertir vertical", isOn: setting(\.invertY))
                } header: {
                    Text("Dirección")
                } footer: {
                    Text("Si al mirar a la derecha el cursor va a la izquierda, activá Invertir horizontal. Si al mirar arriba baja, activá Invertir vertical.")
                }

                DisclosureGroup("Suavizado (One Euro)") {
                    slider(
                        title: "Suavidad",
                        value: setting(\.minCutoff),
                        range: 0.2...8,
                        label: String(format: "%.2f Hz", model.settings.minCutoff)
                    )
                    slider(
                        title: "Respuesta",
                        value: setting(\.beta),
                        range: 0...1,
                        label: String(format: "%.2f", model.settings.beta)
                    )
                    Text("Suavidad más baja filtra más el temblor, con un poco más de retraso. Respuesta más alta reacciona antes cuando girás de golpe.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Recentrar") { model.recenter() }
                    Button(model.isPaused ? "Reanudar" : "Pausar") { model.togglePause() }
                    Spacer()
                    Button("Valores de fábrica") { model.resetSettings() }
                }
            }
            .formStyle(.grouped)
            .padding(20)
        }
        .frame(minWidth: 480, minHeight: 560)
    }

    private var deadZoneDegrees: Binding<Double> {
        Binding(
            get: { model.settings.deadZoneRadians * 180 / .pi },
            set: { degrees in
                model.updateSettings(changing: { $0.deadZoneRadians = degrees * .pi / 180 })
            }
        )
    }

    private func setting(_ keyPath: WritableKeyPath<PointerSettings, Double>) -> Binding<Double> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in
                model.updateSettings(changing: { $0[keyPath: keyPath] = newValue })
            }
        )
    }

    private func setting(_ keyPath: WritableKeyPath<PointerSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in
                model.updateSettings(changing: { $0[keyPath: keyPath] = newValue })
            }
        )
    }

    private func slider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(label)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }

    private func degrees(_ radians: Double) -> String {
        String(format: "%+.1f°", radians * 180 / .pi)
    }
}

private extension AppModel {
    var connectionLabel: String {
        switch connection {
        case .connected: return "Conectados"
        case .disconnected: return "Desconectados"
        case .unavailable: return "No detectados"
        }
    }

    func updateSettings(changing transform: (inout PointerSettings) -> Void) {
        var copy = settings
        transform(&copy)
        updateSettings(copy)
    }
}
