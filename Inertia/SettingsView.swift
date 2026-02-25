import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var config: ScrollConfig

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            advancedTab
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
            profilesTab
                .tabItem { Label("Profiles", systemImage: "person.crop.rectangle.stack") }
            previewTab
                .tabItem { Label("Preview", systemImage: "eye") }
        }
        .frame(width: 520)
    }

    private var previewTab: some View {
        LivePreviewView()
            .environmentObject(config)
            .padding()
    }

    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                enableToggle
                launchAtLoginToggle
                presetSection
                speedSliderSection
                smoothnessSection
                momentumDurationSliderSection
                scrollAccelerationToggle
                footerSection
            }
            .padding()
        }
    }

    private var advancedTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scrollDistanceSliderSection
                horizontalScrollToggle
                reverseDirectionSection
                hotkeysSection
                globalHotkeySection
                AppBlacklistView()
            }
            .padding()
        }
    }

    private var profilesTab: some View {
        ScrollView {
            AppProfilesView()
                .padding()
        }
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
        .toggleStyle(.switch)
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

    private var scrollAccelerationToggle: some View {
        Toggle("Scroll Acceleration", isOn: $config.scrollAccelerationEnabled)
            .toggleStyle(.switch)
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
                .toggleStyle(.switch)
                .font(.headline)

            if config.modifierHotkeysEnabled {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fast Scroll")
                            .font(.subheadline)
                        Picker("", selection: $config.fastModifier) {
                            ForEach(ModifierKey.allCases) { key in
                                Text(key.displayName).tag(key.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        Picker("", selection: Binding(
                            get: { FastMultiplierPreset.allCases.first { $0 != .custom && abs($0.multiplier - config.fastMultiplier) < 0.01 } ?? .custom },
                            set: { if $0 != .custom { config.fastMultiplier = $0.multiplier } }
                        )) {
                            ForEach(FastMultiplierPreset.allCases.filter { $0 != .custom }) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        HStack {
                            Slider(value: $config.fastMultiplier, in: ScrollConfig.fastMultiplierRange, step: 0.1)
                            Text(String(format: "%.1fx", config.fastMultiplier))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Slow Scroll")
                            .font(.subheadline)
                        Picker("", selection: $config.slowModifier) {
                            ForEach(ModifierKey.allCases) { key in
                                Text(key.displayName).tag(key.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        Picker("", selection: Binding(
                            get: { SlowMultiplierPreset.allCases.first { $0 != .custom && abs($0.multiplier - config.slowMultiplier) < 0.01 } ?? .custom },
                            set: { if $0 != .custom { config.slowMultiplier = $0.multiplier } }
                        )) {
                            ForEach(SlowMultiplierPreset.allCases.filter { $0 != .custom }) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        HStack {
                            Slider(value: $config.slowMultiplier, in: ScrollConfig.slowMultiplierRange, step: 0.05)
                            Text(String(format: "%.2fx", config.slowMultiplier))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity)
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

    private var launchAtLoginToggle: some View {
        Toggle("Launch at Login", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    NSLog("[Inertia] Launch at login error: \(error)")
                }
            }
        ))
        .toggleStyle(.switch)
    }

    private var scrollDistanceSliderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scroll Distance")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(ScrollDistancePreset.allCases.filter { $0 != .custom }) { preset in
                    Button(preset.rawValue) {
                        config.applyScrollDistancePreset(preset)
                    }
                    .buttonStyle(.bordered)
                    .tint(config.scrollDistancePreset == preset ? .accentColor : nil)
                }
            }

            sliderRow(
                label: "Multiplier",
                value: $config.scrollDistanceMultiplier,
                range: ScrollConfig.scrollDistanceMultiplierRange,
                step: 0.05,
                format: "%.2fx"
            )
            .onChange(of: config.scrollDistanceMultiplier) { _, _ in
                config.scrollDistanceMultiplierChanged()
            }
        }
    }

    private var horizontalScrollToggle: some View {
        Toggle("Smooth Horizontal Scrolling", isOn: $config.horizontalScrollEnabled)
            .toggleStyle(.switch)
    }

    private var reverseDirectionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Reverse Vertical Scroll", isOn: $config.reverseVertical)
                .toggleStyle(.switch)
            Toggle("Reverse Horizontal Scroll", isOn: $config.reverseHorizontal)
                .toggleStyle(.switch)
        }
    }

    private var globalHotkeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Global Toggle Hotkey", isOn: Binding(
                get: { config.globalHotkeyEnabled },
                set: { newValue in
                    config.globalHotkeyEnabled = newValue
                    HotkeyManager.shared.updateHotkey()
                }
            ))
            .toggleStyle(.switch)
            .font(.headline)

            if config.globalHotkeyEnabled {
                HotkeyRecorderView(
                    keyCode: $config.globalHotkeyKeyCode,
                    modifiers: $config.globalHotkeyModifiers
                )
                .padding(.leading, 4)
            }
        }
    }

    private var footerSection: some View {
        Button("Reset to Defaults") {
            config.resetToDefaults()
            HotkeyManager.shared.updateHotkey()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct HotkeyRecorderView: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @State private var recording = false
    @State private var monitor: Any?
    @State private var rejectedAttempts = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button(action: { toggleRecording() }) {
                    Text(recording ? "Press keys..." : HotkeyManager.displayString(keyCode: keyCode, modifiers: modifiers))
                        .frame(minWidth: 100)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(recording ? .red : nil)

                if recording {
                    Button("Cancel") { stopRecording() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            if recording && rejectedAttempts >= 2 {
                Text("Include a modifier key (Cmd, Option, Control, or Shift)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .onDisappear { stopRecording() }
    }

    private func toggleRecording() {
        if recording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        recording = true
        rejectedAttempts = 0
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let carbonMods = HotkeyManager.carbonModifiers(from: flags)

            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            if carbonMods == 0 {
                rejectedAttempts += 1
                return nil
            }

            keyCode = Int(event.keyCode)
            modifiers = carbonMods
            stopRecording()
            HotkeyManager.shared.updateHotkey()
            return nil
        }
    }

    private func stopRecording() {
        recording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
