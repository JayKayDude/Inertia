# Inertia — Development Roadmap

## v1.0 — Initial Release (Complete)

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
- [x] Parameters: baseSpeed, momentumDuration, smoothness
- [x] Speed presets: Slow / Medium / Fast
- [x] Smoothness presets: Low / Regular / High (controls both smoothness and momentum duration)
- [x] Preset ↔ slider sync (selecting preset moves slider, dragging slider shows "Custom")
- [x] Modifier hotkeys: customizable fast/slow modifier keys with configurable multipliers

### Phase 4 — Settings Window
- [x] `SettingsView.swift` — single-window SwiftUI
- [x] Enable/disable toggle at top (syncs with menubar toggle)
- [x] Preset buttons (speed + smoothness)
- [x] Base Speed slider always visible
- [x] Smoothness slider (momentum duration) below smoothness presets
- [x] "Custom" label when slider != preset
- [x] Modifier hotkeys section with toggle, key pickers, and multiplier sliders
- [x] Reset to Defaults button in footer

### Phase 5 — Live Preview Panel
- [x] `LivePreviewView.swift` — scrollable text inside settings
- [x] Captures mouse wheel input directly (not via CGEventTap)
- [x] Applies current scroll config in real time
- [x] Isolated from system scrolling

### Phase 6 — Credits & Icons
- [x] `CreditsView.swift` — dedicated Credits window (MMF, Freepik attribution, GitHub link)
- [x] Credits menu item in MenuBarExtra (between Settings and Quit)
- [x] Custom app icon — colored triskelion in all required sizes (16–1024)
- [x] Custom menubar icon — B&W template icon (adapts to light/dark mode)
- [x] Removed inline credits from Settings footer

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
- [x] Remove curve steepness setting (imperceptible effect)
- [x] Remove smoothness slider (imperceptible effect, momentum duration is the meaningful control)
- [x] Cap momentum duration range to 0.0–0.5

---

## v2.0 — Full Release

### App Blacklist
- [ ] Per-app blacklist — select apps where smooth scrolling is disabled
- [ ] UI in settings to add/remove apps (app picker or running apps list)
- [ ] ScrollEngine checks frontmost app against blacklist and passes events through unmodified
- [ ] Blacklist persisted via @AppStorage or UserDefaults

### Launch at Login
- [ ] Option to auto-start Inertia on boot
- [ ] Toggle in settings window
- [ ] Use SMAppService (macOS 13+) or LoginItem API

### Horizontal Scroll Smoothing
- [ ] Apply smooth scrolling when Shift is held (Shift+scroll = horizontal, macOS default)
- [ ] Use same speed/smoothness settings as vertical
- [ ] Remove Shift from ModifierKey enum (conflicts with horizontal scroll)

### Scroll Distance Multiplier
- [ ] Simple "scroll more/less per tick" setting without changing the feel
- [ ] Slider in settings

### Reverse Scroll Direction
- [ ] Toggle to reverse vertical scroll direction (independent from trackpad)
- [ ] Toggle to reverse horizontal scroll direction
- [ ] Settings UI with per-axis toggles

### Global Toggle Hotkey
- [ ] Customizable keyboard shortcut to enable/disable Inertia without opening menubar

### Scroll Acceleration Toggle
- [ ] Option to disable the speed curve entirely (linear scrolling)
- [ ] Every tick scrolls the same amount regardless of scroll speed
- [ ] Toggle in settings

### Per-App Scroll Profiles
- [ ] Different speed/smoothness settings per app (not just on/off)
- [x] ~~App icon design~~ (done in v1.0)
