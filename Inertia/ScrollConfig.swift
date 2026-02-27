import SwiftUI
import CoreGraphics

enum ModifierKey: String, CaseIterable, Identifiable {
    case control = "control"
    case option = "option"
    case command = "command"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .control: return "Control"
        case .option: return "Option"
        case .command: return "Command"
        }
    }

    var flags: CGEventFlags {
        switch self {
        case .control: return .maskControl
        case .option: return .maskAlternate
        case .command: return .maskCommand
        }
    }
}

enum SpeedPreset: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"
    case custom = "Custom"

    var id: String { rawValue }

    var baseSpeed: Double {
        switch self {
        case .slow: return 2.0
        case .medium: return 4.0
        case .fast: return 7.0
        case .custom: return -1
        }
    }
}

enum SmoothnessPreset: String, CaseIterable, Identifiable {
    case low = "Low"
    case regular = "Regular"
    case high = "High"
    case custom = "Custom"

    var id: String { rawValue }

    var smoothness: Double {
        switch self {
        case .low: return 0.3
        case .regular: return 0.6
        case .high: return 1.0
        case .custom: return -1
        }
    }

    var momentumDuration: Double {
        switch self {
        case .low: return 0.3
        case .regular: return 0.6
        case .high: return 1.0
        case .custom: return -1
        }
    }
}

enum ScrollDistancePreset: String, CaseIterable, Identifiable {
    case half = "Half"
    case `default` = "Default"
    case double = "Double"
    case triple = "Triple"
    case custom = "Custom"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .half: return 0.5
        case .default: return 1.0
        case .double: return 2.0
        case .triple: return 3.0
        case .custom: return -1
        }
    }
}

enum FastMultiplierPreset: String, CaseIterable, Identifiable {
    case mild = "Mild"
    case normal = "Normal"
    case fast = "Fast"
    case turbo = "Turbo"
    case custom = "Custom"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .mild: return 1.5
        case .normal: return 2.0
        case .fast: return 3.0
        case .turbo: return 5.0
        case .custom: return -1
        }
    }
}

enum EasingPreset: String, CaseIterable, Identifiable, Codable {
    case smooth = "Smooth"
    case snappy = "Snappy"
    case linear = "Linear"
    case gradual = "Gradual"
    var id: String { rawValue }
}

enum SlowMultiplierPreset: String, CaseIterable, Identifiable {
    case light = "Light"
    case half = "Half"
    case quarter = "Quarter"
    case crawl = "Crawl"
    case custom = "Custom"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .light: return 0.75
        case .half: return 0.5
        case .quarter: return 0.25
        case .crawl: return 0.1
        case .custom: return -1
        }
    }
}

struct AppScrollProfile: Codable, Equatable {
    var baseSpeed: Double
    var smoothness: Double
    var momentumDuration: Double
    var scrollAccelerationEnabled: Bool
    var scrollDistanceMultiplier: Double
    var reverseVertical: Bool
    var reverseHorizontal: Bool
    var horizontalScrollEnabled: Bool
    var verticalScrollEnabled: Bool = true
    var modifierHotkeysEnabled: Bool
    var fastModifier: String
    var slowModifier: String
    var fastMultiplier: Double
    var slowMultiplier: Double
    var easingPreset: String = "Smooth"

    init(baseSpeed: Double, smoothness: Double, momentumDuration: Double, scrollAccelerationEnabled: Bool, scrollDistanceMultiplier: Double, reverseVertical: Bool, reverseHorizontal: Bool, horizontalScrollEnabled: Bool, verticalScrollEnabled: Bool = true, modifierHotkeysEnabled: Bool, fastModifier: String, slowModifier: String, fastMultiplier: Double, slowMultiplier: Double, easingPreset: String = "Smooth") {
        self.baseSpeed = baseSpeed
        self.smoothness = smoothness
        self.momentumDuration = momentumDuration
        self.scrollAccelerationEnabled = scrollAccelerationEnabled
        self.scrollDistanceMultiplier = scrollDistanceMultiplier
        self.reverseVertical = reverseVertical
        self.reverseHorizontal = reverseHorizontal
        self.horizontalScrollEnabled = horizontalScrollEnabled
        self.verticalScrollEnabled = verticalScrollEnabled
        self.modifierHotkeysEnabled = modifierHotkeysEnabled
        self.fastModifier = fastModifier
        self.slowModifier = slowModifier
        self.fastMultiplier = fastMultiplier
        self.slowMultiplier = slowMultiplier
        self.easingPreset = easingPreset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseSpeed = try container.decode(Double.self, forKey: .baseSpeed)
        smoothness = try container.decode(Double.self, forKey: .smoothness)
        momentumDuration = try container.decode(Double.self, forKey: .momentumDuration)
        scrollAccelerationEnabled = try container.decode(Bool.self, forKey: .scrollAccelerationEnabled)
        scrollDistanceMultiplier = try container.decode(Double.self, forKey: .scrollDistanceMultiplier)
        reverseVertical = try container.decode(Bool.self, forKey: .reverseVertical)
        reverseHorizontal = try container.decode(Bool.self, forKey: .reverseHorizontal)
        horizontalScrollEnabled = try container.decode(Bool.self, forKey: .horizontalScrollEnabled)
        verticalScrollEnabled = try container.decodeIfPresent(Bool.self, forKey: .verticalScrollEnabled) ?? true
        modifierHotkeysEnabled = try container.decode(Bool.self, forKey: .modifierHotkeysEnabled)
        fastModifier = try container.decode(String.self, forKey: .fastModifier)
        slowModifier = try container.decode(String.self, forKey: .slowModifier)
        fastMultiplier = try container.decode(Double.self, forKey: .fastMultiplier)
        slowMultiplier = try container.decode(Double.self, forKey: .slowMultiplier)
        easingPreset = try container.decodeIfPresent(String.self, forKey: .easingPreset) ?? "Smooth"
    }
}

class ScrollConfig: ObservableObject {
    static let shared = ScrollConfig()

    @AppStorage("enabled") var enabled = true
    @AppStorage("baseSpeed") var baseSpeed = 4.0
    @AppStorage("momentumDuration") var momentumDuration = 0.6
    @AppStorage("smoothness") var smoothness = 0.6

    @AppStorage("modifierHotkeysEnabled") var modifierHotkeysEnabled = true
    @AppStorage("fastModifier") var fastModifier = "control"
    @AppStorage("slowModifier") var slowModifier = "option"
    @AppStorage("fastMultiplier") var fastMultiplier = 2.0
    @AppStorage("slowMultiplier") var slowMultiplier = 0.5

    @AppStorage("horizontalScrollEnabled") var horizontalScrollEnabled = true
    @AppStorage("verticalScrollEnabled") var verticalScrollEnabled = true

    @AppStorage("easingPreset") var easingPreset = "Smooth"

    @AppStorage("scrollAccelerationEnabled") var scrollAccelerationEnabled = true
    @AppStorage("reverseVertical") var reverseVertical = false
    @AppStorage("reverseHorizontal") var reverseHorizontal = false
    @AppStorage("scrollDistanceMultiplier") var scrollDistanceMultiplier = 1.0

    @AppStorage("blacklistedAppsJSON") var blacklistedAppsJSON = "[]"

    var blacklistedBundleIDs: Set<String> {
        get {
            guard let data = blacklistedAppsJSON.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return Set(array)
        }
        set {
            if let data = try? JSONEncoder().encode(Array(newValue).sorted()),
               let string = String(data: data, encoding: .utf8) {
                blacklistedAppsJSON = string
            }
        }
    }

    func isAppBlacklisted(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return blacklistedBundleIDs.contains(bundleID)
    }

    @AppStorage("appProfilesJSON") var appProfilesJSON = "{}"

    var appProfiles: [String: AppScrollProfile] {
        get {
            guard let data = appProfilesJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: AppScrollProfile].self, from: data) else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                appProfilesJSON = string
            }
        }
    }

    func profile(for bundleID: String) -> AppScrollProfile? {
        appProfiles[bundleID]
    }

    func setProfile(_ profile: AppScrollProfile, for bundleID: String) {
        var profiles = appProfiles
        profiles[bundleID] = profile
        appProfiles = profiles
    }

    func removeProfile(for bundleID: String) {
        var profiles = appProfiles
        profiles.removeValue(forKey: bundleID)
        appProfiles = profiles
    }

    func hasProfile(for bundleID: String) -> Bool {
        appProfiles[bundleID] != nil
    }

    func resolvedSettings(for bundleID: String?) -> AppScrollProfile {
        if let bundleID, let p = appProfiles[bundleID] { return p }
        return makeDefaultProfile()
    }

    func makeDefaultProfile() -> AppScrollProfile {
        AppScrollProfile(
            baseSpeed: baseSpeed,
            smoothness: smoothness,
            momentumDuration: momentumDuration,
            scrollAccelerationEnabled: scrollAccelerationEnabled,
            scrollDistanceMultiplier: scrollDistanceMultiplier,
            reverseVertical: reverseVertical,
            reverseHorizontal: reverseHorizontal,
            horizontalScrollEnabled: horizontalScrollEnabled,
            verticalScrollEnabled: verticalScrollEnabled,
            modifierHotkeysEnabled: modifierHotkeysEnabled,
            fastModifier: fastModifier,
            slowModifier: slowModifier,
            fastMultiplier: fastMultiplier,
            slowMultiplier: slowMultiplier,
            easingPreset: easingPreset
        )
    }

    @AppStorage("globalHotkeyEnabled") var globalHotkeyEnabled = false
    @AppStorage("globalHotkeyKeyCode") var globalHotkeyKeyCode = 34
    @AppStorage("globalHotkeyModifiers") var globalHotkeyModifiers = 768

    static let fastMultiplierRange = 1.5...5.0
    static let slowMultiplierRange = 0.1...0.8
    static let scrollDistanceMultiplierRange = 0.25...3.0

    @Published var speedPreset: SpeedPreset = .medium
    @Published var smoothnessPreset: SmoothnessPreset = .regular
    @Published var scrollDistancePreset: ScrollDistancePreset = .default

    static let baseSpeedRange = 0.5...10.0
    static let momentumDurationRange = 0.2...1.0
    static let smoothnessRange = 0.0...1.0

    private var suppressPresetSync = false

    init() {
        syncPresetsFromValues()
    }

    func applyScrollDistancePreset(_ preset: ScrollDistancePreset) {
        guard preset != .custom else { return }
        suppressPresetSync = true
        scrollDistanceMultiplier = preset.multiplier
        scrollDistancePreset = preset
        suppressPresetSync = false
    }

    func scrollDistanceMultiplierChanged() {
        guard !suppressPresetSync else { return }
        let match = ScrollDistancePreset.allCases.first {
            $0 != .custom && abs($0.multiplier - scrollDistanceMultiplier) < 0.01
        }
        scrollDistancePreset = match ?? .custom
    }

    func applySpeedPreset(_ preset: SpeedPreset) {
        guard preset != .custom else { return }
        suppressPresetSync = true
        baseSpeed = preset.baseSpeed
        speedPreset = preset
        suppressPresetSync = false
    }

    func applySmoothnessPreset(_ preset: SmoothnessPreset) {
        guard preset != .custom else { return }
        suppressPresetSync = true
        smoothness = preset.smoothness
        momentumDuration = preset.momentumDuration
        smoothnessPreset = preset
        suppressPresetSync = false
    }

    func applyEasingPreset(_ preset: EasingPreset) {
        easingPreset = preset.rawValue
    }

    func baseSpeedChanged() {
        guard !suppressPresetSync else { return }
        let match = SpeedPreset.allCases.first {
            $0 != .custom && abs($0.baseSpeed - baseSpeed) < 0.01
        }
        speedPreset = match ?? .custom
    }

    func smoothnessChanged() {
        guard !suppressPresetSync else { return }
        syncSmoothnessPreset()
    }

    func momentumDurationChanged() {
        guard !suppressPresetSync else { return }
        smoothness = momentumDuration
        syncSmoothnessPreset()
    }

    private func syncSmoothnessPreset() {
        let match = SmoothnessPreset.allCases.first {
            $0 != .custom
                && abs($0.smoothness - smoothness) < 0.01
                && abs($0.momentumDuration - momentumDuration) < 0.01
        }
        smoothnessPreset = match ?? .custom
    }

    func resetToDefaults() {
        enabled = true
        baseSpeed = 4.0
        momentumDuration = 0.6
        smoothness = 0.6
        speedPreset = .medium
        smoothnessPreset = .regular
        modifierHotkeysEnabled = true
        fastModifier = "control"
        slowModifier = "option"
        fastMultiplier = 2.0
        slowMultiplier = 0.5
        horizontalScrollEnabled = true
        verticalScrollEnabled = true
        scrollAccelerationEnabled = true
        reverseVertical = false
        reverseHorizontal = false
        scrollDistanceMultiplier = 1.0
        scrollDistancePreset = .default
        easingPreset = "Smooth"
        globalHotkeyEnabled = false
        globalHotkeyKeyCode = 34
        globalHotkeyModifiers = 768
        blacklistedAppsJSON = "[]"
        appProfilesJSON = "{}"
    }

    private func syncPresetsFromValues() {
        let speedMatch = SpeedPreset.allCases.first {
            $0 != .custom && abs($0.baseSpeed - baseSpeed) < 0.01
        }
        speedPreset = speedMatch ?? .custom

        let smoothMatch = SmoothnessPreset.allCases.first {
            $0 != .custom
                && abs($0.smoothness - smoothness) < 0.01
                && abs($0.momentumDuration - momentumDuration) < 0.01
        }
        smoothnessPreset = smoothMatch ?? .custom

        let distMatch = ScrollDistancePreset.allCases.first {
            $0 != .custom && abs($0.multiplier - scrollDistanceMultiplier) < 0.01
        }
        scrollDistancePreset = distMatch ?? .custom
    }
}
