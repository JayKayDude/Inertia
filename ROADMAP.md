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

## v2.1 — UI Polish (Complete)

### Animated Settings Window
- [x] Settings window animates height on tab switch
- [x] GeometryReader → NotificationCenter → AppDelegate → NSAnimationContext pipeline
- [x] Width locked at 520pt, height user-adjustable
- [x] HiDPI/non-HiDPI monitor transition handling

### About Window
- [x] Renamed CreditsView → AboutView
- [x] App info, developer identity, credits in dedicated window

### Vertical Scroll Toggle
- [x] Option to disable vertical scroll smoothing independently

---

## v2.2 — Easing Curves (Complete)

### Easing Presets
- [x] 5 presets: Linear, Gradual, Smooth (default), Snappy, Custom
- [x] Per-frame easing formulas in ScrollEngine
- [x] Visual easing curve preview with live momentum dot indicator
- [x] Preset buttons with "Default" caption under Smooth

### Custom Easing — Slider Mode
- [x] Decay slider (0.90–0.995) controls friction rate
- [x] Shape slider (-0.50–0.15) controls curve shape (gradual ↔ snappy)
- [x] Parametric formula: `v *= min(friction * (1 - shape * (1-t)), 1.0)`

### Custom Easing — Point Editor Mode
- [x] Click on graph to add control points
- [x] Drag to reposition points (clamped to bounds, x-sorted)
- [x] Click to select points (orange highlight, larger radius)
- [x] Delete key or Delete Point button to remove selected point
- [x] Fixed endpoints at (0, 1.0) and (1, 0) — not movable/removable
- [x] Monotone cubic interpolation (Fritsch-Carlson) for smooth curves
- [x] Engine sets velocity absolutely from curve: `v = initialV * curveValue(t)`
- [x] Points stored as JSON-encoded `[{x, y}]` in @AppStorage

### Undo/Redo & Reset
- [x] CustomEasingUndoManager with separate stacks per mode (sliders vs points)
- [x] Cmd+Z / Shift+Cmd+Z keyboard shortcuts via .keyboardShortcut on buttons
- [x] Undo/Redo buttons in UI
- [x] Reset Custom button (pushes current state to undo before resetting)

### Per-App Profile Support
- [x] Each app profile stores independent custom easing settings
- [x] Mode, friction, shape, and points per profile
- [x] Momentum dot only shows when scrolling on the profiled app
- [x] activeScrollBundleID tracking in ScrollEngine

---

## v2.3 — Update Checker & Export/Import (Complete)

### Lightweight Update Checker
- [x] Check GitHub Releases API on launch and every 24 hours
- [x] Parse tag_name, numeric version comparison
- [x] Show "Update Available" in menubar menu and About window
- [x] Link to GitHub Releases page for download

### Settings Export / Import
- [x] Export all @AppStorage values to a plist file
- [x] Import settings from a plist file, overwriting current config
- [x] UI via titlebar ellipsis menu button

---

## v2.3.1 — Scroll Modifier Fixes (Complete)

- [x] Slow modifier minimum impulse floor (prevents swallowed ticks)
- [x] Slow modifier speed cap (prevents acceleration ramp)
- [x] Fast modifier ramp tuning (threshold 4, gentler curve 1.1x initial)
- [x] Regular scroll acceleration threshold increased to 3 swipes

---

## v2.4 — Preferences Tab & Polish (Complete)

### Preferences Tab
- [x] New "Preferences" tab in settings window
- [x] Menubar icon style picker (Low Profile / Colorful)
- [x] Launch at Login moved from General to Preferences
- [x] Export/Import buttons moved from titlebar to Preferences tab
- [x] Manual "Check Now" update button with status display

### Dock Folder Fix
- [x] Smooth scrolling in Dock folder pop-ups (com.apple.dock.helper)
- [x] Pixel delta substituted with line delta for Dock helper process

### UX Polish
- [x] Removed titlebar separator line in settings window
- [x] Added top padding to tab bar for breathing room
- [x] Added Mos credit to README and About window
- [x] Added AI disclosure section to README
- [x] "Support Inertia — Coming Soon" in About window

