# Inertia — Development Roadmap

## v0.8 — Working App (Complete)

Scroll engine, menubar, settings window with sliders, presets, live preview.

### Phase 0 — Documentation Update
- [x] Update all project docs to reflect finalized plan

### Phase 1 — Project Setup & Menubar Shell
- [x] Xcode project: "Inertia", Swift + SwiftUI, macOS 15.0
- [x] `LSUIElement = YES` in Info.plist (no Dock icon)
- [x] `InertiaApp.swift` — SwiftUI App with `MenuBarExtra`
- [x] Menu: Enable toggle, Settings, Quit
- [x] `AccessibilityManager.swift` — permission check, prompt, poll

### Phase 2 — Scroll Engine Core
- [x] `ScrollEngine.swift` — CGEventTap intercepting scrollWheel
- [x] Mouse vs trackpad detection (trackpad passthrough)
- [x] Velocity tracking — time between ticks with rolling average
- [x] Speedup curve — MMF formula (b=1.1, p=1.33, t=8)
- [x] Momentum/inertia — half-life friction on DispatchSourceTimer
- [x] MMF-matching event construction (field 55, three delta fields)

### Phase 3 — Configuration & Presets
- [x] `ScrollConfig.swift` — @AppStorage backed
- [x] Parameters: baseSpeed, curveExponent, momentumDuration, smoothness
- [x] Speed presets: Slow / Medium / Fast
- [x] Smoothness presets: Low / Regular / High
- [x] Preset ↔ slider sync (selecting preset moves slider, dragging slider shows "Custom")

### Phase 4 — Settings Window
- [x] `SettingsView.swift` — single-window SwiftUI
- [x] Preset buttons (speed + smoothness)
- [x] Base Speed slider always visible
- [x] "Custom" label when slider != preset
- [x] Expandable Advanced section (Curve Steepness, Momentum Duration)
- [x] MMF attribution footer, Reset to Defaults

### Phase 5 — Live Preview Panel
- [x] `LivePreviewView.swift` — scrollable text inside settings
- [x] Captures mouse wheel input directly (not via CGEventTap)
- [x] Applies current scroll config in real time
- [x] Isolated from system scrolling

### Bug Fixes & Tuning
- [x] Fix Terminal scrolling too fast (FixedPtDeltaAxis1 was pixel, not line)
- [x] Fix speed curve b=2.0 → b=1.1 matching MMF
- [x] Direction-only rawDelta (like MMF)
- [x] Thread safety with NSLock (replaced DispatchQueue.sync)
- [x] Fix enable/disable toggle (@AppStorage + custom Binding)
- [x] Tick rate smoothing (rolling average of 3)
- [x] Raise velocityThreshold to stop sub-pixel animations
- [x] Remove dead minTickSize code
- [x] Fix lineDelta consistency (use rounded pixels, not raw)
- [x] Fix timer/frameInterval mismatch

---

## v1.0 — Full Release

### Visual Curve Editor
- [ ] "Custom" preset reveals graph view
- [ ] X: scroll velocity, Y: speed multiplier
- [ ] Draggable Bezier control points
- [ ] Real-time preview updates
- [ ] Save custom curves as named presets

### Other
- [ ] Per-app scroll profiles
- [ ] Import/export settings
- [ ] App icon design
- [ ] Signed .app / .dmg distribution
- [ ] Homebrew tap
