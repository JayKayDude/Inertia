import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var config: ScrollConfig

    var body: some View {
        VStack(spacing: 0) {
            LivePreviewView()
                .frame(height: 180)
                .padding()

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                enableToggle
                presetSection
                speedSliderSection
                smoothnessSection
                momentumDurationSliderSection
                hotkeysSection
            }
            .padding()

            Divider()

            footerSection
                .padding()
        }
        .frame(width: 400)
    }

    private var enableToggle: some View {
        Toggle("Enable Inertia", isOn: Binding(
            get: { config.enabled },
            set: { newValue in
                config.enabled = newValue
                if newValue {
                    ScrollEngine.shared.start()
                } else {
                    ScrollEngine.shared.stop()
                }
            }
        ))
        .font(.headline)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speed")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(SpeedPreset.allCases.filter { $0 != .custom }) { preset in
                    Button(preset.rawValue) {
                        config.applySpeedPreset(preset)
                    }
                    .buttonStyle(.bordered)
                    .tint(config.speedPreset == preset ? .accentColor : nil)
                }
            }
        }
    }

    private var speedSliderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Base Speed")
                Spacer()
                if config.speedPreset == .custom {
                    Text("Custom")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Text(String(format: "%.1f", config.baseSpeed))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(value: $config.baseSpeed, in: ScrollConfig.baseSpeedRange, step: 0.1)
                .onChange(of: config.baseSpeed) { _, _ in
                    config.baseSpeedChanged()
                }
        }
    }

    private var smoothnessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Smoothness")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(SmoothnessPreset.allCases.filter { $0 != .custom }) { preset in
                    Button(preset.rawValue) {
                        config.applySmoothnessPreset(preset)
                    }
                    .buttonStyle(.bordered)
                    .tint(config.smoothnessPreset == preset ? .accentColor : nil)
                }
            }
        }
    }

    private var hotkeysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Modifier Hotkeys", isOn: $config.modifierHotkeysEnabled)
                .font(.headline)

            if config.modifierHotkeysEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fast Scroll")
                            .font(.subheadline)
                        Picker("", selection: $config.fastModifier) {
                            ForEach(ModifierKey.allCases) { key in
                                Text(key.displayName).tag(key.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        sliderRow(
                            label: "Multiplier",
                            value: $config.fastMultiplier,
                            range: ScrollConfig.fastMultiplierRange,
                            step: 0.1,
                            format: "%.1fx"
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Slow Scroll")
                            .font(.subheadline)
                        Picker("", selection: $config.slowModifier) {
                            ForEach(ModifierKey.allCases) { key in
                                Text(key.displayName).tag(key.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        sliderRow(
                            label: "Multiplier",
                            value: $config.slowMultiplier,
                            range: ScrollConfig.slowMultiplierRange,
                            step: 0.05,
                            format: "%.2fx"
                        )
                    }
                }
                .padding(.leading, 4)
            }
        }
    }

    private var momentumDurationSliderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Smoothness")
                Spacer()
                if config.smoothnessPreset == .custom {
                    Text("Custom")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Text(String(format: "%.2fs", config.momentumDuration))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(value: $config.momentumDuration, in: ScrollConfig.momentumDurationRange, step: 0.05)
                .onChange(of: config.momentumDuration) { _, _ in
                    config.momentumDurationChanged()
                }
        }
    }

    private func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String = "%.1f"
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private var footerSection: some View {
        Button("Reset to Defaults") {
            config.resetToDefaults()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
