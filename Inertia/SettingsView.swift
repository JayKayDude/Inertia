import SwiftUI
import ServiceManagement

func decodePoints(_ json: String) -> [CurvePoint] {
    guard let data = json.data(using: .utf8),
          let pts = try? JSONDecoder().decode([CurvePoint].self, from: data) else { return [] }
    return pts
}

func encodePoints(_ pts: [CurvePoint]) -> String {
    guard let data = try? JSONEncoder().encode(pts),
          let str = String(data: data, encoding: .utf8) else { return "[]" }
    return str
}

class CustomEasingUndoManager: ObservableObject {
    struct SliderState: Equatable {
        var friction: Double
        var shape: Double
    }

    private var sliderUndo: [SliderState] = []
    private var sliderRedo: [SliderState] = []
    private var pointsUndo: [[CurvePoint]] = []
    private var pointsRedo: [[CurvePoint]] = []

    var canUndoSliders: Bool { !sliderUndo.isEmpty }
    var canRedoSliders: Bool { !sliderRedo.isEmpty }
    var canUndoPoints: Bool { !pointsUndo.isEmpty }
    var canRedoPoints: Bool { !pointsRedo.isEmpty }

    private func notifyChange() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    func pushSliderState(_ state: SliderState) {
        if sliderUndo.last == state { return }
        sliderUndo.append(state)
        sliderRedo.removeAll()
        notifyChange()
    }

    func undoSliders(current: SliderState) -> SliderState? {
        guard let prev = sliderUndo.popLast() else { return nil }
        sliderRedo.append(current)
        notifyChange()
        return prev
    }

    func redoSliders(current: SliderState) -> SliderState? {
        guard let next = sliderRedo.popLast() else { return nil }
        sliderUndo.append(current)
        notifyChange()
        return next
    }

    func pushPointsState(_ points: [CurvePoint]) {
        pointsUndo.append(points)
        pointsRedo.removeAll()
        notifyChange()
    }

    func undoPoints(current: [CurvePoint]) -> [CurvePoint]? {
        guard let prev = pointsUndo.popLast() else { return nil }
        pointsRedo.append(current)
        notifyChange()
        return prev
    }

    func redoPoints(current: [CurvePoint]) -> [CurvePoint]? {
        guard let next = pointsRedo.popLast() else { return nil }
        pointsUndo.append(current)
        notifyChange()
        return next
    }

    func clear() {
        sliderUndo.removeAll()
        sliderRedo.removeAll()
        pointsUndo.removeAll()
        pointsRedo.removeAll()
        notifyChange()
    }
}

extension Notification.Name {
    static let settingsContentHeightChanged = Notification.Name("settingsContentHeightChanged")
}

struct SettingsView: View {
    @EnvironmentObject var config: ScrollConfig
    @ObservedObject private var engine = ScrollEngine.shared
    @StateObject private var easingUndo = CustomEasingUndoManager()
    @State private var selectedCurvePoint: Int? = nil
    @State private var loginItemRefresh = false
    @State private var verticalOptionsExpanded = false
    @State private var horizontalOptionsExpanded = false
    @ObservedObject private var updateChecker = UpdateChecker.shared
    @State private var selectedTab = 0
    @State private var tabHeights: [Int: CGFloat] = [3: 532]
    @State private var isCheckingForUpdates = false
    @State private var updateCheckStatus = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
                .tag(0)
            advancedTab
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
                .tag(1)
            profilesTab
                .tabItem { Label("Profiles", systemImage: "person.crop.rectangle.stack") }
                .tag(2)
            previewTab
                .tabItem { Label("Preview", systemImage: "eye") }
                .tag(3)
            preferencesTab
                .tabItem { Label("Preferences", systemImage: "wrench.and.screwdriver") }
                .tag(4)
        }
        .frame(width: 520)
        .onChange(of: selectedTab) { _, newTab in
            if let height = tabHeights[newTab] {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .settingsContentHeightChanged,
                        object: nil,
                        userInfo: ["height": height]
                    )
                }
            }
        }
    }

    private func updateTabHeight(_ tab: Int, _ height: CGFloat) {
        let old = tabHeights[tab]
        tabHeights[tab] = height
        if tab == selectedTab && (old == nil || abs(height - old!) > 5) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .settingsContentHeightChanged,
                    object: nil,
                    userInfo: ["height": height]
                )
            }
        }
    }

    private var previewTab: some View {
        ScrollView {
            LivePreviewView()
                .environmentObject(config)
                .frame(height: 500)
                .padding()
        }
    }

    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                enableToggle
                presetSection
                speedSliderSection
                smoothnessSection
                momentumDurationSliderSection
                easingSection
                scrollAccelerationToggle
                footerSection
            }
            .padding()
            .background(
                GeometryReader { geo in
                    Color.clear.onChange(of: geo.size.height, initial: true) { _, newHeight in
                        updateTabHeight(0, newHeight)
                    }
                }
            )
        }
    }

    private var advancedTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scrollDistanceSliderSection
                scrollAxesSection
                hotkeysSection
                globalHotkeySection
                AppBlacklistView()
            }
            .padding()
            .background(
                GeometryReader { geo in
                    Color.clear.onChange(of: geo.size.height, initial: true) { _, newHeight in
                        updateTabHeight(1, newHeight)
                    }
                }
            )
        }
    }

    private var profilesTab: some View {
        ScrollView {
            AppProfilesView()
                .padding()
                .background(
                    GeometryReader { geo in
                        Color.clear.onChange(of: geo.size.height, initial: true) { _, newHeight in
                            updateTabHeight(2, newHeight)
                        }
                    }
                )
        }
    }

    private var preferencesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menubar Icon")
                        .font(.headline)
                    HStack(spacing: 12) {
                        iconStyleButton(title: "Low Profile", value: "lowProfile", imageName: "MenuBarIcon")
                        iconStyleButton(title: "Colorful", value: "colorful", imageName: "MenuBarIconColorful")
                    }
                    Text("Change takes effect after restarting Inertia.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                launchAtLoginToggle

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.headline)
                    HStack(spacing: 12) {
                        Button("Export Settings...") {
                            ScrollConfig.shared.exportSettings()
                        }
                        Button("Import Settings...") {
                            ScrollConfig.shared.importSettings()
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Updates")
                        .font(.headline)
                    HStack(spacing: 12) {
                        Button("Check Now") {
                            isCheckingForUpdates = true
                            updateCheckStatus = ""
                            UpdateChecker.shared.checkForUpdates()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isCheckingForUpdates = false
                                if let version = UpdateChecker.shared.availableVersion {
                                    updateCheckStatus = "v\(version) available"
                                } else {
                                    updateCheckStatus = "Up to date"
                                }
                            }
                        }
                        .disabled(isCheckingForUpdates)

                        if isCheckingForUpdates {
                            ProgressView()
                                .controlSize(.small)
                        } else if !updateCheckStatus.isEmpty {
                            Text(updateCheckStatus)
                                .foregroundStyle(updateChecker.availableVersion != nil ? .blue : .secondary)
                        }
                    }
                    if let version = updateChecker.availableVersion, !isCheckingForUpdates {
                        Button("Download v\(version)") {
                            NSWorkspace.shared.open(UpdateChecker.releasesPageURL)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .background(
                GeometryReader { geo in
                    Color.clear.onChange(of: geo.size.height, initial: true) { _, newHeight in
                        updateTabHeight(4, newHeight)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func iconStyleButton(title: String, value: String, imageName: String) -> some View {
        let content = Button {
            config.menubarIconStyle = value
        } label: {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 50)
        }
        if config.menubarIconStyle == value {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered)
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
                    if config.speedPreset == preset {
                        Button(preset.rawValue) { config.applySpeedPreset(preset) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(preset.rawValue) { config.applySpeedPreset(preset) }
                            .buttonStyle(.bordered)
                    }
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

    private var easingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Easing")
                .font(.headline)

            HStack(alignment: .top, spacing: 8) {
                ForEach(EasingPreset.allCases) { preset in
                    VStack(spacing: 2) {
                        if config.easingPreset == preset.rawValue {
                            Button(preset.rawValue) { config.applyEasingPreset(preset) }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button(preset.rawValue) { config.applyEasingPreset(preset) }
                                .buttonStyle(.bordered)
                        }

                        Text("Default")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .opacity(preset == .smooth ? 1 : 0)
                    }
                }
            }

            if config.easingPreset == "Custom" {
                Picker("Mode", selection: $config.customEasingMode) {
                    Text("Sliders").tag("sliders")
                    Text("Curve Editor").tag("points")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            let currentPreset = EasingPreset(rawValue: config.easingPreset) ?? .smooth
            let isPointEditing = currentPreset == .custom && config.customEasingMode == "points"

            EasingCurveView(
                preset: currentPreset,
                momentumDuration: config.momentumDuration,
                momentumProgress: engine.momentumProgress,
                customFriction: config.customEasingFriction,
                customShape: config.customEasingShape,
                customMode: config.customEasingMode,
                customPoints: decodePoints(config.customEasingPoints),
                isEditing: isPointEditing,
                onPointsChanged: { pts in
                    config.customEasingPoints = encodePoints(pts)
                },
                onEditingStarted: {
                    easingUndo.pushPointsState(decodePoints(config.customEasingPoints))
                },
                selectedPointIndex: selectedCurvePoint,
                onSelectionChanged: { selectedCurvePoint = $0 }
            )
            .frame(height: isPointEditing ? 140 : 80)

            if config.easingPreset == "Custom" {
                if config.customEasingMode == "sliders" {
                    customSlidersSection
                } else {
                    Text("Click to add or select points. Drag to move.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                customUndoRedoResetSection
            }
        }
    }

    private var customSlidersSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Decay")
                Spacer()
                Text(String(format: "%.3f", config.customEasingFriction))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $config.customEasingFriction, in: ScrollConfig.customEasingFrictionRange, step: 0.005) { editing in
                if editing {
                    easingUndo.pushSliderState(.init(friction: config.customEasingFriction, shape: config.customEasingShape))
                }
            }

            HStack {
                Text("Shape")
                Spacer()
                Text(String(format: "%.2f", config.customEasingShape))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $config.customEasingShape, in: ScrollConfig.customEasingShapeRange, step: 0.01) { editing in
                if editing {
                    easingUndo.pushSliderState(.init(friction: config.customEasingFriction, shape: config.customEasingShape))
                }
            }
        }
    }

    private var customUndoRedoResetSection: some View {
        VStack(spacing: 8) {
            let isSliders = config.customEasingMode == "sliders"
            let canUndo = isSliders ? easingUndo.canUndoSliders : easingUndo.canUndoPoints
            let canRedo = isSliders ? easingUndo.canRedoSliders : easingUndo.canRedoPoints

            HStack(spacing: 12) {
                Button {
                    performUndo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!canUndo)
                .keyboardShortcut("z", modifiers: .command)

                Button {
                    performRedo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])

                if !isSliders && selectedCurvePoint != nil {
                    Button(role: .destructive) {
                        if let idx = selectedCurvePoint {
                            deleteSelectedPoint(at: idx)
                        }
                    } label: {
                        Label("Delete Point", systemImage: "trash")
                    }
                    .keyboardShortcut(.delete, modifiers: [])
                }
            }

            Button("Reset Custom") {
                performReset()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func performUndo() {
        if config.customEasingMode == "sliders" {
            let current = CustomEasingUndoManager.SliderState(friction: config.customEasingFriction, shape: config.customEasingShape)
            if let prev = easingUndo.undoSliders(current: current) {
                config.customEasingFriction = prev.friction
                config.customEasingShape = prev.shape
            }
        } else {
            let current = decodePoints(config.customEasingPoints)
            if let prev = easingUndo.undoPoints(current: current) {
                config.customEasingPoints = encodePoints(prev)
                selectedCurvePoint = nil
            }
        }
    }

    private func performRedo() {
        if config.customEasingMode == "sliders" {
            let current = CustomEasingUndoManager.SliderState(friction: config.customEasingFriction, shape: config.customEasingShape)
            if let next = easingUndo.redoSliders(current: current) {
                config.customEasingFriction = next.friction
                config.customEasingShape = next.shape
            }
        } else {
            let current = decodePoints(config.customEasingPoints)
            if let next = easingUndo.redoPoints(current: current) {
                config.customEasingPoints = encodePoints(next)
                selectedCurvePoint = nil
            }
        }
    }

    private func performReset() {
        if config.customEasingMode == "sliders" {
            easingUndo.pushSliderState(.init(friction: config.customEasingFriction, shape: config.customEasingShape))
            config.customEasingFriction = 0.96
            config.customEasingShape = 0.0
        } else {
            easingUndo.pushPointsState(decodePoints(config.customEasingPoints))
            config.customEasingPoints = "[]"
            selectedCurvePoint = nil
        }
    }

    private func deleteSelectedPoint(at index: Int) {
        var pts = decodePoints(config.customEasingPoints)
        guard index < pts.count else { return }
        easingUndo.pushPointsState(pts)
        pts.remove(at: index)
        config.customEasingPoints = encodePoints(pts)
        selectedCurvePoint = nil
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
                    if config.smoothnessPreset == preset {
                        Button(preset.rawValue) { config.applySmoothnessPreset(preset) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(preset.rawValue) { config.applySmoothnessPreset(preset) }
                            .buttonStyle(.bordered)
                    }
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
            get: { _ = loginItemRefresh; return SMAppService.mainApp.status == .enabled },
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
                loginItemRefresh.toggle()
            }
        ))
        .toggleStyle(.switch)
        .onAppear { loginItemRefresh.toggle() }
    }

    private var scrollDistanceSliderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scroll Distance")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(ScrollDistancePreset.allCases.filter { $0 != .custom }) { preset in
                    if config.scrollDistancePreset == preset {
                        Button(preset.rawValue) { config.applyScrollDistancePreset(preset) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(preset.rawValue) { config.applyScrollDistancePreset(preset) }
                            .buttonStyle(.bordered)
                    }
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

    private var scrollAxesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scrolling")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Toggle("Smooth Vertical Scrolling", isOn: $config.verticalScrollEnabled)
                        .toggleStyle(.switch)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            verticalOptionsExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(verticalOptionsExpanded ? 90 : 0))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if verticalOptionsExpanded {
                    Toggle("Reverse Direction", isOn: $config.reverseVertical)
                        .toggleStyle(.switch)
                        .padding(.leading, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Toggle("Smooth Horizontal Scrolling", isOn: $config.horizontalScrollEnabled)
                        .toggleStyle(.switch)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            horizontalOptionsExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(horizontalOptionsExpanded ? 90 : 0))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if horizontalOptionsExpanded {
                    Toggle("Reverse Direction", isOn: $config.reverseHorizontal)
                        .toggleStyle(.switch)
                        .padding(.leading, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
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
