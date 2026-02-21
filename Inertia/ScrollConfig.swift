import SwiftUI
import CoreGraphics

enum ModifierKey: String, CaseIterable, Identifiable {
    case shift = "shift"
    case control = "control"
    case option = "option"
    case command = "command"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shift: return "Shift"
        case .control: return "Control"
        case .option: return "Option"
        case .command: return "Command"
        }
    }

    var flags: CGEventFlags {
        switch self {
        case .shift: return .maskShift
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

    static let fastMultiplierRange = 1.5...5.0
    static let slowMultiplierRange = 0.1...0.8

    @Published var speedPreset: SpeedPreset = .medium
    @Published var smoothnessPreset: SmoothnessPreset = .regular

    static let baseSpeedRange = 0.5...10.0
    static let momentumDurationRange = 0.0...0.5
    static let smoothnessRange = 0.0...1.0

    private var suppressPresetSync = false

    init() {
        syncPresetsFromValues()
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
    }
}
