# Project Memory

> Permanent record of architectural decisions, constraints, and context. Do not delete entries — mark them superseded instead.

## Project Identity
- **Name:** Inertia
- **Type:** macOS menubar app
- **Purpose:** Replaces stepped mouse wheel scrolling with smooth, physics-based inertial scrolling
- **Created:** 2026-02-18
- **Author:** Jayke Collier
- **GitHub:** https://github.com/JayKayDude/Inertia
- **License:** Open source, free
- **Target OS:** macOS Sequoia (15.0+)

## Foundation
- Built from scratch in **pure Swift/SwiftUI** — no Obj-C bridging
- Uses MMF's physics formulas as **reference only** (not forked code)
- Speedup curve: `y = a * pow(1.1, (x-t) * c) + 1 - a` (b=1.1, p=1.33, t=8)
- Language: Swift 5.9+
- UI: SwiftUI
- Editor: VS Code + Claude Code + Xcode

## Architectural Decisions

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2026-02-18 | Governance docs created at project root | Standard AI governance initialization | Active |
| 2026-02-18 | Menubar-only app, no Dock icon | Lightweight background utility pattern | Active |
| 2026-02-18 | Intercept mouse wheel events only, leave trackpads alone | Trackpads already have system-level inertia | Active |
| 2026-02-19 | **Build from scratch, not fork MMF** | MMF is Obj-C with deep dependencies; clean Swift rewrite is simpler | Active |
| 2026-02-19 | **v1.0/v2.0 versioning** | v1.0 = initial release, v2.0 = curve editor + per-app profiles | Active |
| 2026-02-19 | **Smoothness presets: Low/Regular/High** | ~~Off/Low/Regular/High~~ — Off removed since smooth scrolling is the app's purpose | Active |
| 2026-02-19 | Base Speed slider always visible | Most users only need one slider | Active |
| 2026-02-19 | Preset ↔ slider sync with "Custom" label | Selecting preset moves slider; dragging away shows Custom | Active |
| 2026-02-20 | **MMF event construction**: CGEvent(source: nil), field 55=22, three delta fields | Terminal and other apps read different delta fields; must set all three consistently | Active |
| 2026-02-20 | **Direction-only rawDelta** | MMF ignores rawDelta magnitude, only uses sign; prevents per-app scroll speed inconsistency | Active |
| 2026-02-20 | **Half-life friction model** | `friction = pow(0.5, 1/halfLifeFrames)` — approximates MMF's drag curve | Active |
| 2026-02-20 | **NSLock for thread safety** | DispatchQueue.sync caused deadlocks (CGEvent.post dispatches to main thread) | Active |
| 2026-02-20 | **Custom Binding for enable toggle** | @AppStorage on ObservableObject doesn't trigger onChange; custom Binding calls start/stop directly | Active |
| 2026-02-20 | **Credits window (not inline footer)** | Consolidates all attribution (MMF, Freepik icon) into dedicated window accessible from menubar | Active |
| 2026-02-20 | **Custom menubar icon (template)** | B&W icon with `template-rendering-intent` so macOS adapts it to light/dark mode | Active |
| 2026-02-20 | **App icon from Freepik/Flaticon** | Colored triskelion icon, resized via sips to all 10 required macOS sizes | Active |
| 2026-02-20 | **Removed minTickSize** | Was in config/UI but never used by engine; dead code removed | Active |
| 2026-02-20 | **Tick rate smoothing (rolling avg of 3)** | Matches MMF's RollingAverage(capacity: 3) for stable speed curve input | Active |
| 2026-02-20 | **velocityThreshold = 120** | Stops animation when <1 px/frame; old value (3.0) ran animation far too long | Active |
| 2026-02-20 | **Modifier hotkeys** | Customizable fast/slow modifier keys (Control/Option default) with multiplier sliders; uses CGEventSource.flagsState not event.flags | Active |
| 2026-02-20 | **Enable toggle in settings** | Custom Binding pattern (same as menubar) starts/stops ScrollEngine; syncs via shared config | Active |
| 2026-02-20 | **Removed curveExponent setting** | Effect was imperceptible — formula self-cancels at different c values; hardcoded to 1.5 | Active |
| 2026-02-20 | **Removed smoothness slider** | Effect was imperceptible due to compensation factor; momentum duration is the meaningful control | Active |
| 2026-02-20 | **Renamed momentum duration to "Smoothness" in UI** | User-facing label; internally still momentumDuration | Active |
| 2026-02-20 | **Capped momentum duration at 0.5** | Range 0.0–0.5 (was 0.0–2.0); values above 0.5 felt uncontrollable | Superseded by 2026-02-24 range 0.2–1.0 |
| 2026-02-20 | **SmoothnessPreset includes Custom** | Matches SpeedPreset pattern; deselects when either smoothness or momentumDuration diverges from preset values | Active |
| 2026-02-23 | **Horizontal scroll: single-axis, no phases** | Single-axis events matching MMF continuous mode. No scroll phase fields (99/123). Shared gesture lifecycle across axes (no ended/began on axis switch). | Active |
| 2026-02-23 | **Shift removed from ModifierKey** | Shift+scroll = horizontal scroll (macOS default). Conflicts with modifier hotkey usage. | Active |
| 2026-02-23 | **Carbon RegisterEventHotKey for global hotkey** | No permissions needed for non-sandboxed apps. Callback verifies hotkey ID via GetEventParameter. | Active |
| 2026-02-23 | **SMAppService for launch at login** | Reads system status directly (no local @AppStorage). Users can remove login items from System Settings independently. | Active |
| 2026-02-23 | **velocityThreshold lowered to 30.0** | Was 120.0 (1 px/frame). At 30.0, slow single-tick scrolls get visible momentum (~360ms vs ~83ms). | Active |
| 2026-02-23 | **Fast scroll acceleration resets on direction/axis change** | consecutiveSwipeCount zeroed on direction reversal and axis switch to prevent carryover. | Active |
| 2026-02-23 | **CGEventTap callback uses passUnretained** | passRetained leaked every passthrough event. passUnretained is correct since system already owns the event. | Active |
| 2026-02-23 | **Scroll acceleration toggle** | Bypasses both computeSpeed() curve and fastScrollFactor() when disabled. Returns base speed * 2.0 to compensate. Moved to General tab. | Active |
| 2026-02-23 | **Reverse scroll direction per-axis** | Applied via effectiveDirection in processScroll. Separate toggles for vertical/horizontal. | Active |
| 2026-02-23 | **Scroll distance multiplier** | Applied after speed curve, before modifier hotkeys. Presets: Half(0.5x), Default(1.0x), Double(2.0x), Triple(3.0x). Range 0.25–3.0x. | Active |
| 2026-02-23 | **Tabbed settings window** | General/Advanced/Preview tabs. General opens first. Replaced single VStack layout. | Active |
| 2026-02-23 | **Expanded live preview** | Three test areas: vertical-only, horizontal-only, combined (both axes). PreviewTextView handles deltaX and deltaY. | Active |
| 2026-02-23 | **Resizable settings window** | Added .resizable to styleMask. Default 420x650. | Active |
| 2026-02-23 | **App blacklist: JSON in @AppStorage** | JSON-encoded [String] array. Frontmost app cached via NSWorkspace notification. NSMenu for + button (SwiftUI Menu borderlessButton has hit area issues). | Active |
| 2026-02-24 | **Per-app profiles: non-optional fields** | AppScrollProfile has all fields non-optional. Initialized from globals via makeDefaultProfile() when app is added. No override toggles — every setting always has a value. | Active |
| 2026-02-24 | **Profile storage: JSON in @AppStorage** | `[String: AppScrollProfile]` encoded as JSON string in appProfilesJSON. Same pattern as blacklist. | Active |
| 2026-02-24 | **Window-under-cursor detection** | `CGWindowListCopyWindowInfo` + `NSRunningApplication(processIdentifier:)` to find app owning window under cursor. Fallback to cachedFrontmostBundleID. Used for both blacklist and profiles. | Active |
| 2026-02-24 | **Smoothness compensation: pow(ratio, 0.15)** | 4th-root-like curve. Low smoothness gets ~1.4x compensation instead of 8x linear. Prevents speed explosion at low smoothness. | Active |
| 2026-02-24 | **Momentum duration range 0.2–1.0** | Was 0.0–0.5. Extended to match SmoothnessPreset.high (1.0). Minimum raised to 0.2 to prevent zero-momentum feel. | Active |
| 2026-02-24 | **Two-column modifier hotkeys layout** | Fast Scroll (left) and Slow Scroll (right) side by side. Each has dropdown key picker, segmented speed presets, and slider. | Active |
| 2026-02-24 | **All toggles use .switch style** | Consistent across SettingsView and AppProfilesView. No checkboxes anywhere. | Active |
| 2026-02-24 | **Lock covers all mutable engine state** | NSLock scope expanded to cover config caching, gesture tracking, velocity update, and animationTimer access. Prevents data races between event tap and animation threads. | Active |
| 2026-02-24 | **Momentum window check throttled to ~10Hz** | DispatchQueue.main.sync in animationFrame only runs every 12 frames (~10/sec) instead of 120. Prevents scroll jank when main thread is busy. | Active |
| 2026-02-24 | **Velocity zeroing uses effectiveDirection** | Prevents reverse scroll from killing momentum every tick. Was using raw direction which conflicted with reversed effectiveDirection. | Active |
| 2026-02-24 | **Settings window width 520pt** | Was 420pt. Increased to fit two-column modifier hotkeys layout. | Active |

## Versioning

### v1.0 — Initial Release (implemented)
- Scroll engine (CGEventTap + DispatchSourceTimer + MMF physics)
- Menubar with enable toggle
- Settings window: enable toggle, speed/smoothness presets with sliders, modifier hotkeys, live preview
- Modifier hotkeys for fast/slow scrolling (customizable keys and multipliers)
- Accessibility permission prompt
- Thread-safe animation with NSLock

### v2.0 — Full Release (feature-complete)
- ~~Launch at login~~ (done)
- ~~Horizontal scroll smoothing~~ (done)
- ~~Global toggle hotkey~~ (done)
- ~~Scroll acceleration toggle~~ (done)
- ~~Scroll distance multiplier~~ (done)
- ~~Reverse scroll direction per-axis~~ (done)
- ~~Tabbed settings + expanded preview~~ (done)
- ~~App blacklist~~ (done)
- ~~Per-app scroll profiles~~ (done)
- Signed distribution (pending)

## Scroll Engine Technical Details

### Event Construction (matches MMF)
- `CGEvent(source: nil)` — NOT `CGEventCreateScrollWheelEvent`
- Field 55 = 22 (event subtype)
- `scrollWheelEventIsContinuous` = 1
- `DeltaAxis1` = signedCeil(pixels / 10) — integer line delta
- `PointDeltaAxis1` = integer pixel delta
- `FixedPtDeltaAxis1` = (pixels / 10) * 65536 — 16.16 fixed-point LINE delta

### Key Constants
- `pixelsPerTick` = 45.0
- `pixelsPerLine` = 10.0
- `frameInterval` = 1/120
- `velocityThreshold` = 30.0

### Speed Curve
```
b = 1.1, c = 1.5 (hardcoded), t = 8.0, p = 1.33
a = (p - 1) / (b^c - 1)
multiplier = a * pow(b, (x - t) * c) + 1 - a
clamped to [1.0, 3.0]
```

## Constraints
- iCloud Drive sync — avoid large binary files or rapid file churn
- macOS-only (Darwin 25.3.0 dev environment)
- CGEventTap requires Accessibility permission from user on first launch
- Git repo root is inside Inertia folder (not home directory)

## Phase History
| Phase | Description | Completed |
|-------|-------------|-----------|
| Init  | Governance scaffolding, GitHub repo, project docs | 2026-02-18 |
| 0     | Documentation update for finalized plan | 2026-02-19 |
| 1     | Project setup & menubar shell | 2026-02-19 |
| 2     | Scroll engine core | 2026-02-19 |
| 3     | Configuration & presets | 2026-02-19 |
| 4     | Settings window | 2026-02-19 |
| 5     | Live preview panel | 2026-02-19 |
| —     | Scroll feel tuning & bug fixes | 2026-02-20 |
| 6     | Credits window & custom icons | 2026-02-20 |

## Key File Locations
| File | Purpose |
|------|---------|
| `Inertia/InertiaApp.swift` | App entry, MenuBarExtra, enable toggle, settings/credits windows |
| `Inertia/ScrollEngine.swift` | CGEventTap, velocity, momentum, event posting |
| `Inertia/ScrollConfig.swift` | Parameters, presets, @AppStorage |
| `Inertia/AccessibilityManager.swift` | Permission check & prompt |
| `Inertia/SettingsView.swift` | Main settings window |
| `Inertia/LivePreviewView.swift` | Scrollable preview panel |
| `Inertia/HotkeyManager.swift` | Carbon global hotkey registration and callback |
| `Inertia/CreditsView.swift` | Credits window (MMF, Freepik attribution) |
| `Inertia/AppBlacklistView.swift` | Per-app blacklist UI + shared helpers (appIcon, appName, AddMenuTarget) |
| `Inertia/AppProfilesView.swift` | Per-app profile editor with Speed/Behavior tabs |
| `CLAUDE.md` | Standing instructions for Claude Code |
| `SESSION-STATE.md` | Per-session progress tracker |
| `PROJECT-MEMORY.md` | This file — decisions and context |
| `LEARNING-LOG.md` | Recurring problems and solutions |
| `README.md` | Public-facing project description |
| `ROADMAP.md` | Detailed development roadmap |
