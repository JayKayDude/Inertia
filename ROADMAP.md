# Inertia — Development Roadmap

## v0.8 — Working App

Scroll engine, menubar, settings window with sliders, presets, live preview.

### Phase 0 — Documentation Update
- [x] Update all project docs to reflect finalized plan

### Phase 1 — Project Setup & Menubar Shell
- [ ] Xcode project: "Inertia", Swift + SwiftUI, macOS 15.0
- [ ] `LSUIElement = YES` in Info.plist (no Dock icon)
- [ ] `InertiaApp.swift` — SwiftUI App with `MenuBarExtra`
- [ ] Menu: Enable toggle, Settings, Quit
- [ ] `AccessibilityManager.swift` — permission check, prompt, poll

### Phase 2 — Scroll Engine Core
- [ ] `ScrollEngine.swift` — CGEventTap intercepting scrollWheel
- [ ] Mouse vs trackpad detection (trackpad passthrough)
- [ ] Velocity tracking — time between ticks
- [ ] Speedup curve — MMF formula
- [ ] Momentum/inertia — drag decay on CVDisplayLink
- [ ] Smooth CGEvent scroll event posting

### Phase 3 — Configuration & Presets
- [ ] `ScrollConfig.swift` — @AppStorage backed
- [ ] Parameters: baseSpeed, curveExponent, momentumDuration, minTickSize, smoothness
- [ ] Speed presets: Slow / Medium / Fast
- [ ] Smoothness presets: Off / Low / Regular / High
- [ ] Preset ↔ slider sync (selecting preset moves slider, dragging slider shows "Custom")

### Phase 4 — Settings Window
- [ ] `SettingsView.swift` — single-window SwiftUI
- [ ] Preset buttons (speed + smoothness)
- [ ] Base Speed slider always visible
- [ ] "Custom" label when slider != preset
- [ ] Expandable Advanced section (Curve Steepness, Momentum Duration, Min Tick Size)
- [ ] MMF attribution footer, Reset to Defaults

### Phase 5 — Live Preview Panel
- [ ] `LivePreviewView.swift` — scrollable text/list inside settings
- [ ] Captures mouse wheel input directly (not via CGEventTap)
- [ ] Applies current scroll config in real time
- [ ] Isolated from system scrolling

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
