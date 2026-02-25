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
- [x] Cap momentum duration range to 0.2–1.0

---

## v2.0 — Full Release

### App Blacklist
- [x] Per-app blacklist — select apps where smooth scrolling is disabled
- [x] UI in settings to add/remove apps (app picker or running apps list)
- [x] ScrollEngine checks window-under-cursor app against blacklist and passes events through unmodified
- [x] Blacklist persisted via @AppStorage (JSON-encoded array)

### Launch at Login
- [x] Option to auto-start Inertia on boot
- [x] Toggle in settings window
- [x] Use SMAppService (macOS 13+)

### Horizontal Scroll Smoothing
- [x] Apply smooth scrolling when Shift is held (Shift+scroll = horizontal, macOS default)
- [x] Use same speed/smoothness settings as vertical
- [x] Remove Shift from ModifierKey enum (conflicts with horizontal scroll)

### Scroll Distance Multiplier
- [x] Simple "scroll more/less per tick" setting without changing the feel
- [x] Presets (Half/Default/Double/Triple) with slider
- [x] Multiplier applied in ScrollEngine after speed curve

### Reverse Scroll Direction
- [x] Toggle to reverse vertical scroll direction (independent from trackpad)
- [x] Toggle to reverse horizontal scroll direction
- [x] Settings UI with per-axis toggles

### Global Toggle Hotkey
- [x] Customizable keyboard shortcut to enable/disable Inertia without opening menubar
- [x] Custom key recorder UI in settings
- [x] Carbon RegisterEventHotKey with hotkey ID verification

### Scroll Acceleration Toggle
- [x] Option to disable the speed curve entirely (linear scrolling)
- [x] Every tick scrolls the same amount regardless of scroll speed (2x base speed to compensate)
- [x] Toggle in General tab

### Tabbed Settings Window
- [x] Reorganized settings into General/Advanced/Preview tabs
- [x] Expanded live preview with vertical, horizontal, and combined scroll test areas
- [x] PreviewTextView supports horizontal scroll processing
- [x] Resizable settings window

### Per-App Scroll Profiles
- [x] Different speed/smoothness/distance/modifier settings per app
- [x] Profile editor UI with Speed and Behavior sub-tabs
- [x] Profiles stored as JSON in @AppStorage, initialized from global defaults
- [x] ScrollEngine resolves per-app settings via window-under-cursor detection
- [x] Blacklist warning shown when profiled app is also blacklisted
- [x] ~~App icon design~~ (done in v1.0)

---

## v3.0 — Pro Version

### Free vs Pro Tier ($5)

**Free tier:**
- Enable/disable toggle, launch at login
- Speed presets (Slow/Medium/Fast) — no custom slider
- Smoothness presets (Low/Regular/High) — no custom slider
- Scroll distance presets (Half/Default/Double/Triple) — no custom slider
- Scroll acceleration toggle
- Reverse scroll direction
- Smooth horizontal scrolling toggle
- Global toggle hotkey

**Pro tier ($5):**
- All custom sliders (base speed, smoothness, scroll distance)
- Modifier hotkeys (fast/slow scroll with customizable keys and multipliers)
- Per-app scroll profiles (full profile editor)
- Per-app blacklist

### Implementation Plan
- [ ] Simple local flag (`isPro` in @AppStorage) — placeholder for real payment
- [ ] Gate custom sliders behind Pro (presets remain free)
- [ ] Hide per-app profiles tab entirely for free users
- [ ] Hide blacklist section for free users
- [ ] Hide modifier hotkeys section for free users
- [ ] Add "Inertia Pro" note in app listing available Pro features
- [ ] Add Pro features list to README
- [ ] Wire up actual payment (StoreKit 2 or license key — TBD)
