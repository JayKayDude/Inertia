import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AppProfilesView: View {
    @EnvironmentObject var config: ScrollConfig
    @ObservedObject private var engine = ScrollEngine.shared
    @State private var runningApps: [NSRunningApplication] = []
    @State private var selection: String?
    @State private var profileTab = 0
    @StateObject private var easingUndo = CustomEasingUndoManager()
    @State private var selectedCurvePoint: Int? = nil

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
        .onChange(of: config.appProfilesJSON) { _, _ in
            if let sel = selection, config.profile(for: sel) == nil {
                selection = nil
            }
        }
        .onChange(of: selection) { _, _ in easingUndo.clear(); selectedCurvePoint = nil }
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
                        if matchesSpeedPreset(profile, preset) {
                            Button(preset.rawValue) { updateProfile(bundleID: bundleID) { $0.baseSpeed = preset.baseSpeed } }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button(preset.rawValue) { updateProfile(bundleID: bundleID) { $0.baseSpeed = preset.baseSpeed } }
                                .buttonStyle(.bordered)
                        }
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
                        if matchesSmoothnessPreset(profile, preset) {
                            Button(preset.rawValue) {
                                updateProfile(bundleID: bundleID) {
                                    $0.smoothness = preset.smoothness
                                    $0.momentumDuration = preset.momentumDuration
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(preset.rawValue) {
                                updateProfile(bundleID: bundleID) {
                                    $0.smoothness = preset.smoothness
                                    $0.momentumDuration = preset.momentumDuration
                                }
                            }
                            .buttonStyle(.bordered)
                        }
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

            // Easing
            VStack(alignment: .leading, spacing: 8) {
                Text("Easing")
                    .font(.headline)

                HStack(alignment: .top, spacing: 8) {
                    ForEach(EasingPreset.allCases) { preset in
                        VStack(spacing: 2) {
                            if profile.easingPreset == preset.rawValue {
                                Button(preset.rawValue) { updateProfile(bundleID: bundleID) { $0.easingPreset = preset.rawValue } }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button(preset.rawValue) { updateProfile(bundleID: bundleID) { $0.easingPreset = preset.rawValue } }
                                    .buttonStyle(.bordered)
                            }

                            Text("Default")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .opacity(preset == .smooth ? 1 : 0)
                        }
                    }
                }

                if profile.easingPreset == "Custom" {
                    Picker("Mode", selection: profileBinding(bundleID: bundleID, keyPath: \.customEasingMode)) {
                        Text("Sliders").tag("sliders")
                        Text("Curve Editor").tag("points")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                let currentPreset = EasingPreset(rawValue: profile.easingPreset) ?? .smooth
                let isPointEditing = currentPreset == .custom && profile.customEasingMode == "points"

                EasingCurveView(
                    preset: currentPreset,
                    momentumDuration: profile.momentumDuration,
                    momentumProgress: engine.activeScrollBundleID == bundleID ? engine.momentumProgress : nil,
                    customFriction: profile.customEasingFriction,
                    customShape: profile.customEasingShape,
                    customMode: profile.customEasingMode,
                    customPoints: decodePoints(profile.customEasingPoints),
                    isEditing: isPointEditing,
                    onPointsChanged: { pts in
                        updateProfile(bundleID: bundleID) { $0.customEasingPoints = encodePoints(pts) }
                    },
                    onEditingStarted: {
                        easingUndo.pushPointsState(decodePoints(profile.customEasingPoints))
                    },
                    selectedPointIndex: selectedCurvePoint,
                    onSelectionChanged: { selectedCurvePoint = $0 }
                )
                .frame(height: isPointEditing ? 140 : 80)

                if profile.easingPreset == "Custom" {
                    if profile.customEasingMode == "sliders" {
                        profileCustomSliders(bundleID: bundleID, profile: profile)
                    } else {
                        Text("Click to add or select points. Drag to move.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    profileUndoRedoResetSection(bundleID: bundleID, profile: profile)
                }
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
                        if matchesDistancePreset(profile, preset) {
                            Button(preset.rawValue) { updateProfile(bundleID: bundleID) { $0.scrollDistanceMultiplier = preset.multiplier } }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button(preset.rawValue) { updateProfile(bundleID: bundleID) { $0.scrollDistanceMultiplier = preset.multiplier } }
                                .buttonStyle(.bordered)
                        }
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

    // MARK: - Custom easing sliders

    @ViewBuilder
    private func profileCustomSliders(bundleID: String, profile: AppScrollProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Decay")
                Spacer()
                Text(String(format: "%.3f", profile.customEasingFriction))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: profileBinding(bundleID: bundleID, keyPath: \.customEasingFriction),
                in: ScrollConfig.customEasingFrictionRange,
                step: 0.005
            ) { editing in
                if editing {
                    easingUndo.pushSliderState(.init(friction: profile.customEasingFriction, shape: profile.customEasingShape))
                }
            }

            HStack {
                Text("Shape")
                Spacer()
                Text(String(format: "%.2f", profile.customEasingShape))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: profileBinding(bundleID: bundleID, keyPath: \.customEasingShape),
                in: ScrollConfig.customEasingShapeRange,
                step: 0.01
            ) { editing in
                if editing {
                    easingUndo.pushSliderState(.init(friction: profile.customEasingFriction, shape: profile.customEasingShape))
                }
            }
        }
    }

    @ViewBuilder
    private func profileUndoRedoResetSection(bundleID: String, profile: AppScrollProfile) -> some View {
        VStack(spacing: 8) {
            let isSliders = profile.customEasingMode == "sliders"
            let canUndo = isSliders ? easingUndo.canUndoSliders : easingUndo.canUndoPoints
            let canRedo = isSliders ? easingUndo.canRedoSliders : easingUndo.canRedoPoints

            HStack(spacing: 12) {
                Button {
                    profilePerformUndo(bundleID: bundleID)
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!canUndo)
                .keyboardShortcut("z", modifiers: .command)

                Button {
                    profilePerformRedo(bundleID: bundleID)
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])

                if !isSliders && selectedCurvePoint != nil {
                    Button(role: .destructive) {
                        if let idx = selectedCurvePoint {
                            profileDeleteSelectedPoint(bundleID: bundleID, at: idx)
                        }
                    } label: {
                        Label("Delete Point", systemImage: "trash")
                    }
                    .keyboardShortcut(.delete, modifiers: [])
                }
            }

            Button("Reset Custom") {
                profilePerformReset(bundleID: bundleID)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func profilePerformUndo(bundleID: String) {
        let profile = config.profile(for: bundleID) ?? config.makeDefaultProfile()
        if profile.customEasingMode == "sliders" {
            let current = CustomEasingUndoManager.SliderState(friction: profile.customEasingFriction, shape: profile.customEasingShape)
            if let prev = easingUndo.undoSliders(current: current) {
                updateProfile(bundleID: bundleID) {
                    $0.customEasingFriction = prev.friction
                    $0.customEasingShape = prev.shape
                }
            }
        } else {
            let current = decodePoints(profile.customEasingPoints)
            if let prev = easingUndo.undoPoints(current: current) {
                updateProfile(bundleID: bundleID) { $0.customEasingPoints = encodePoints(prev) }
                selectedCurvePoint = nil
            }
        }
    }

    private func profilePerformRedo(bundleID: String) {
        let profile = config.profile(for: bundleID) ?? config.makeDefaultProfile()
        if profile.customEasingMode == "sliders" {
            let current = CustomEasingUndoManager.SliderState(friction: profile.customEasingFriction, shape: profile.customEasingShape)
            if let next = easingUndo.redoSliders(current: current) {
                updateProfile(bundleID: bundleID) {
                    $0.customEasingFriction = next.friction
                    $0.customEasingShape = next.shape
                }
            }
        } else {
            let current = decodePoints(profile.customEasingPoints)
            if let next = easingUndo.redoPoints(current: current) {
                updateProfile(bundleID: bundleID) { $0.customEasingPoints = encodePoints(next) }
                selectedCurvePoint = nil
            }
        }
    }

    private func profilePerformReset(bundleID: String) {
        let profile = config.profile(for: bundleID) ?? config.makeDefaultProfile()
        if profile.customEasingMode == "sliders" {
            easingUndo.pushSliderState(.init(friction: profile.customEasingFriction, shape: profile.customEasingShape))
            updateProfile(bundleID: bundleID) {
                $0.customEasingFriction = 0.96
                $0.customEasingShape = 0.0
            }
        } else {
            easingUndo.pushPointsState(decodePoints(profile.customEasingPoints))
            updateProfile(bundleID: bundleID) { $0.customEasingPoints = "[]" }
            selectedCurvePoint = nil
        }
    }

    private func profileDeleteSelectedPoint(bundleID: String, at index: Int) {
        let profile = config.profile(for: bundleID) ?? config.makeDefaultProfile()
        var pts = decodePoints(profile.customEasingPoints)
        guard index < pts.count else { return }
        easingUndo.pushPointsState(pts)
        pts.remove(at: index)
        updateProfile(bundleID: bundleID) { $0.customEasingPoints = encodePoints(pts) }
        selectedCurvePoint = nil
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
