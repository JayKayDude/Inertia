import SwiftUI

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

    var id: String { rawValue }

    var smoothness: Double {
        switch self {
        case .low: return 0.3
        case .regular: return 0.6
        case .high: return 1.0
        }
    }

    var momentumDuration: Double {
        switch self {
        case .low: return 0.3
        case .regular: return 0.6
        case .high: return 1.0
        }
    }
}

class ScrollConfig: ObservableObject {
    static let shared = ScrollConfig()

    @AppStorage("enabled") var enabled = true
    @AppStorage("baseSpeed") var baseSpeed = 4.0
    @AppStorage("curveExponent") var curveExponent = 1.5
    @AppStorage("momentumDuration") var momentumDuration = 0.6
    @AppStorage("smoothness") var smoothness = 0.6

    @Published var speedPreset: SpeedPreset = .medium
    @Published var smoothnessPreset: SmoothnessPreset = .regular

    static let baseSpeedRange = 0.5...10.0
    static let curveExponentRange = 0.5...4.0
    static let momentumDurationRange = 0.0...2.0
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
        let match = SmoothnessPreset.allCases.first {
            abs($0.smoothness - smoothness) < 0.01
        }
        smoothnessPreset = match ?? .regular
    }

    func resetToDefaults() {
        enabled = true
        baseSpeed = 4.0
        curveExponent = 1.5
        momentumDuration = 0.6
        smoothness = 0.6
        speedPreset = .medium
        smoothnessPreset = .regular
    }

    private func syncPresetsFromValues() {
        let speedMatch = SpeedPreset.allCases.first {
            $0 != .custom && abs($0.baseSpeed - baseSpeed) < 0.01
        }
        speedPreset = speedMatch ?? .custom

        let smoothMatch = SmoothnessPreset.allCases.first {
            abs($0.smoothness - smoothness) < 0.01
        }
        smoothnessPreset = smoothMatch ?? .regular
    }
}
