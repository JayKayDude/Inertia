import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AppProfilesView: View {
    @EnvironmentObject var config: ScrollConfig
    @State private var runningApps: [NSRunningApplication] = []
    @State private var selection: String?
    @State private var profileTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per-App Profiles")
                .font(.headline)
            Text("Override scroll settings for specific apps.")
                .font(.caption)
                .foregroundStyle(.secondary)

            let ids = config.appProfiles.keys.sorted()

            List(ids, id: \.self, selection: $selection) { bundleID in
                HStack(spacing: 8) {
                    appIcon(for: bundleID)
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(appName(for: bundleID))
                        .lineLimit(1)
                }
            }
            .listStyle(.bordered)
            .frame(height: 128)

            HStack(spacing: 0) {
                Button {
                    showAddMenu()
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .frame(width: 28, height: 22)

                Divider()
                    .frame(height: 16)

                Button {
                    if let sel = selection {
                        config.removeProfile(for: sel)
                        selection = nil
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .frame(width: 28, height: 22)
                .disabled(selection == nil)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(nsColor: .separatorColor)))

            if let sel = selection {
                if config.isAppBlacklisted(sel) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("This app is also blacklisted. Blacklist takes priority — scrolling will pass through.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                Text("Settings for \(appName(for: sel))")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("", selection: $profileTab) {
                    Text("Speed").tag(0)
                    Text("Behavior").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if profileTab == 0 {
                    speedSettings(bundleID: sel)
                } else {
                    behaviorSettings(bundleID: sel)
                }
            }
        }
        .onAppear { refreshRunningApps() }
    }

    // MARK: - Speed tab (mirrors General + Advanced speed sections)

    @ViewBuilder
    private func speedSettings(bundleID: String) -> some View {
        let profile = config.profile(for: bundleID) ?? config.makeDefaultProfile()

        VStack(alignment: .leading, spacing: 16) {

            // Speed presets + Base Speed slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Speed")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(SpeedPreset.allCases.filter { $0 != .custom }) { preset in
                        Button(preset.rawValue) {
                            updateProfile(bundleID: bundleID) { $0.baseSpeed = preset.baseSpeed }
                        }
                        .buttonStyle(.bordered)
                        .tint(matchesSpeedPreset(profile, preset) ? .accentColor : nil)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Base Speed")
                    Spacer()
                    if currentSpeedPreset(profile) == .custom {
                        Text("Custom")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    Text(String(format: "%.1f", profile.baseSpeed))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: profileBinding(bundleID: bundleID, keyPath: \.baseSpeed),
                    in: ScrollConfig.baseSpeedRange,
                    step: 0.1
                )
            }

            // Smoothness presets + Smoothness slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Smoothness")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(SmoothnessPreset.allCases.filter { $0 != .custom }) { preset in
                        Button(preset.rawValue) {
                            updateProfile(bundleID: bundleID) {
                                $0.smoothness = preset.smoothness
                                $0.momentumDuration = preset.momentumDuration
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(matchesSmoothnessPreset(profile, preset) ? .accentColor : nil)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Smoothness")
                    Spacer()
                    if currentSmoothnessPreset(profile) == .custom {
                        Text("Custom")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    Text(String(format: "%.2fs", profile.momentumDuration))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { (config.profile(for: bundleID) ?? config.makeDefaultProfile()).momentumDuration },
                        set: { newValue in
                            updateProfile(bundleID: bundleID) {
                                $0.momentumDuration = newValue
                                $0.smoothness = newValue
                            }
                        }
                    ),
                    in: ScrollConfig.momentumDurationRange,
                    step: 0.05
                )
            }

            // Scroll Acceleration
            Toggle("Scroll Acceleration", isOn: profileBinding(bundleID: bundleID, keyPath: \.scrollAccelerationEnabled))
                .toggleStyle(.switch)

            // Scroll Distance presets + Multiplier slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Scroll Distance")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(ScrollDistancePreset.allCases.filter { $0 != .custom }) { preset in
                        Button(preset.rawValue) {
                            updateProfile(bundleID: bundleID) { $0.scrollDistanceMultiplier = preset.multiplier }
                        }
                        .buttonStyle(.bordered)
                        .tint(matchesDistancePreset(profile, preset) ? .accentColor : nil)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Multiplier")
                        Spacer()
                        Text(String(format: "%.2fx", profile.scrollDistanceMultiplier))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: profileBinding(bundleID: bundleID, keyPath: \.scrollDistanceMultiplier),
                        in: ScrollConfig.scrollDistanceMultiplierRange,
                        step: 0.05
                    )
                }
            }
        }
    }

    // MARK: - Behavior tab (mirrors Advanced tab)

    @ViewBuilder
    private func behaviorSettings(bundleID: String) -> some View {
        let profile = config.profile(for: bundleID) ?? config.makeDefaultProfile()

        VStack(alignment: .leading, spacing: 16) {
            Toggle("Smooth Vertical Scrolling", isOn: profileBinding(bundleID: bundleID, keyPath: \.verticalScrollEnabled))
                .toggleStyle(.switch)

            Toggle("Smooth Horizontal Scrolling", isOn: profileBinding(bundleID: bundleID, keyPath: \.horizontalScrollEnabled))
                .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Reverse Vertical Scroll", isOn: profileBinding(bundleID: bundleID, keyPath: \.reverseVertical))
                    .toggleStyle(.switch)
                Toggle("Reverse Horizontal Scroll", isOn: profileBinding(bundleID: bundleID, keyPath: \.reverseHorizontal))
                    .toggleStyle(.switch)
            }

            // Modifier Hotkeys (mirrors Advanced > hotkeysSection)
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Modifier Hotkeys", isOn: profileBinding(bundleID: bundleID, keyPath: \.modifierHotkeysEnabled))
                    .toggleStyle(.switch)
                    .font(.headline)

                if profile.modifierHotkeysEnabled {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fast Scroll")
                                .font(.subheadline)
                            Picker("", selection: profileBinding(bundleID: bundleID, keyPath: \.fastModifier)) {
                                ForEach(ModifierKey.allCases) { key in
                                    Text(key.displayName).tag(key.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()

                            Picker("", selection: Binding(
                                get: { FastMultiplierPreset.allCases.first { $0 != .custom && abs($0.multiplier - profile.fastMultiplier) < 0.01 } ?? .custom },
                                set: { preset in
                                    if preset != .custom {
                                        updateProfile(bundleID: bundleID) { $0.fastMultiplier = preset.multiplier }
                                    }
                                }
                            )) {
                                ForEach(FastMultiplierPreset.allCases.filter { $0 != .custom }) { preset in
                                    Text(preset.rawValue).tag(preset)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()

                            HStack {
                                Slider(
                                    value: profileBinding(bundleID: bundleID, keyPath: \.fastMultiplier),
                                    in: ScrollConfig.fastMultiplierRange,
                                    step: 0.1
                                )
                                Text(String(format: "%.1fx", profile.fastMultiplier))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .frame(width: 36, alignment: .trailing)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Slow Scroll")
                                .font(.subheadline)
                            Picker("", selection: profileBinding(bundleID: bundleID, keyPath: \.slowModifier)) {
                                ForEach(ModifierKey.allCases) { key in
                                    Text(key.displayName).tag(key.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()

                            Picker("", selection: Binding(
                                get: { SlowMultiplierPreset.allCases.first { $0 != .custom && abs($0.multiplier - profile.slowMultiplier) < 0.01 } ?? .custom },
                                set: { preset in
                                    if preset != .custom {
                                        updateProfile(bundleID: bundleID) { $0.slowMultiplier = preset.multiplier }
                                    }
                                }
                            )) {
                                ForEach(SlowMultiplierPreset.allCases.filter { $0 != .custom }) { preset in
                                    Text(preset.rawValue).tag(preset)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()

                            HStack {
                                Slider(
                                    value: profileBinding(bundleID: bundleID, keyPath: \.slowMultiplier),
                                    in: ScrollConfig.slowMultiplierRange,
                                    step: 0.05
                                )
                                Text(String(format: "%.2fx", profile.slowMultiplier))
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
    }

    // MARK: - Helpers

    private func profileSliderRow(
        label: String,
        value: Double,
        binding: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: binding, in: range, step: step)
        }
    }

    private func updateProfile(bundleID: String, _ update: (inout AppScrollProfile) -> Void) {
        var p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
        update(&p)
        config.setProfile(p, for: bundleID)
    }

    // MARK: - Preset matching

    private func matchesSpeedPreset(_ profile: AppScrollProfile, _ preset: SpeedPreset) -> Bool {
        abs(preset.baseSpeed - profile.baseSpeed) < 0.01
    }

    private func currentSpeedPreset(_ profile: AppScrollProfile) -> SpeedPreset {
        SpeedPreset.allCases.first { $0 != .custom && matchesSpeedPreset(profile, $0) } ?? .custom
    }

    private func matchesSmoothnessPreset(_ profile: AppScrollProfile, _ preset: SmoothnessPreset) -> Bool {
        abs(preset.smoothness - profile.smoothness) < 0.01
            && abs(preset.momentumDuration - profile.momentumDuration) < 0.01
    }

    private func currentSmoothnessPreset(_ profile: AppScrollProfile) -> SmoothnessPreset {
        SmoothnessPreset.allCases.first { $0 != .custom && matchesSmoothnessPreset(profile, $0) } ?? .custom
    }

    private func matchesDistancePreset(_ profile: AppScrollProfile, _ preset: ScrollDistancePreset) -> Bool {
        abs(preset.multiplier - profile.scrollDistanceMultiplier) < 0.01
    }

    // MARK: - Profile bindings

    private func profileBinding(bundleID: String, keyPath: WritableKeyPath<AppScrollProfile, Double>) -> Binding<Double> {
        Binding(
            get: {
                let p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
                return p[keyPath: keyPath]
            },
            set: { newValue in
                var p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
                p[keyPath: keyPath] = newValue
                config.setProfile(p, for: bundleID)
            }
        )
    }

    private func profileBinding(bundleID: String, keyPath: WritableKeyPath<AppScrollProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: {
                let p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
                return p[keyPath: keyPath]
            },
            set: { newValue in
                var p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
                p[keyPath: keyPath] = newValue
                config.setProfile(p, for: bundleID)
            }
        )
    }

    private func profileBinding(bundleID: String, keyPath: WritableKeyPath<AppScrollProfile, String>) -> Binding<String> {
        Binding(
            get: {
                let p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
                return p[keyPath: keyPath]
            },
            set: { newValue in
                var p = config.profile(for: bundleID) ?? config.makeDefaultProfile()
                p[keyPath: keyPath] = newValue
                config.setProfile(p, for: bundleID)
            }
        )
    }

    // MARK: - Add menu

    private func showAddMenu() {
        let menu = NSMenu()

        let runningItem = NSMenuItem(title: "Running Apps", action: nil, keyEquivalent: "")
        let runningSubmenu = NSMenu()
        let existing = Set(config.appProfiles.keys)
        let available = runningApps.filter { app in
            guard let id = app.bundleIdentifier else { return false }
            return !existing.contains(id) && app.activationPolicy == .regular
        }
        if available.isEmpty {
            let emptyItem = NSMenuItem(title: "No apps available", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            runningSubmenu.addItem(emptyItem)
        } else {
            for app in available {
                let item = NSMenuItem(title: app.localizedName ?? app.bundleIdentifier ?? "Unknown", action: #selector(AddMenuTarget.menuAction(_:)), keyEquivalent: "")
                item.representedObject = app.bundleIdentifier
                item.target = AddMenuTarget.shared
                runningSubmenu.addItem(item)
            }
        }
        runningItem.submenu = runningSubmenu
        menu.addItem(runningItem)

        let browseItem = NSMenuItem(title: "Browse...", action: #selector(AddMenuTarget.browseAction(_:)), keyEquivalent: "")
        browseItem.target = AddMenuTarget.shared
        menu.addItem(browseItem)

        AddMenuTarget.shared.onAdd = { [self] bundleID in addApp(bundleID: bundleID) }
        AddMenuTarget.shared.onBrowse = { [self] in browseForApp() }

        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    private func addApp(bundleID: String?) {
        guard let bundleID else { return }
        config.setProfile(config.makeDefaultProfile(), for: bundleID)
        selection = bundleID
    }

    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Select an app to create a profile for"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let id = Bundle(url: url)?.bundleIdentifier {
            addApp(bundleID: id)
        }
    }

    private func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}
