import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var config: ScrollConfig
    @State private var showAdvanced = false

    var body: some View {
        VStack(spacing: 0) {
            LivePreviewView()
                .frame(height: 180)
                .padding()

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                presetSection
                speedSliderSection
                smoothnessSection
                advancedSection
            }
            .padding()

            Divider()

            footerSection
                .padding()
        }
        .frame(width: 400)
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
                ForEach(SmoothnessPreset.allCases) { preset in
                    Button(preset.rawValue) {
                        config.applySmoothnessPreset(preset)
                    }
                    .buttonStyle(.bordered)
                    .tint(config.smoothnessPreset == preset ? .accentColor : nil)
                }
            }
        }
    }

    private var advancedSection: some View {
        DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 12) {
                sliderRow(
                    label: "Curve Steepness",
                    value: $config.curveExponent,
                    range: ScrollConfig.curveExponentRange,
                    step: 0.1
                )

                sliderRow(
                    label: "Momentum Duration",
                    value: $config.momentumDuration,
                    range: ScrollConfig.momentumDurationRange,
                    step: 0.05,
                    format: "%.2fs"
                )

            }
            .padding(.top, 8)
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
        VStack(spacing: 8) {
            HStack {
                Text("Based on ")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                +
                Text("[Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix)")
                    .font(.caption)

                Spacer()

                Link("GitHub", destination: URL(string: "https://github.com/JayKayDude/Inertia")!)
                    .font(.caption)
            }

            Button("Reset to Defaults") {
                config.resetToDefaults()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
