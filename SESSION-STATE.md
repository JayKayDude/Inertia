# Session State

> Updated each session. Tracks current position, blockers, and next actions.

## Last Updated
2026-02-24

## Current Phase
v2.0 — 8/8 features complete

## What Was Done This Session
- Per-app scroll profiles (feature 8/8) — full implementation
  - AppScrollProfile struct with non-optional fields (initialized from globals on add)
  - Profile editor UI (AppProfilesView.swift) with Speed/Behavior sub-tabs
  - Speed tab: presets (speed, smoothness, distance), sliders, acceleration toggle
  - Behavior tab: horizontal scroll, reverse direction, modifier hotkeys (two-column layout)
  - Modifier hotkey presets (FastMultiplierPreset, SlowMultiplierPreset) as segmented pickers
  - Profile resolution via resolvedSettings(for:) in ScrollEngine
  - Window-under-cursor detection (bundleIDUnderCursor) for accurate app targeting
  - Blacklist warning when profiled app is also blacklisted
- UI refinements across the app
  - All toggles switched to .toggleStyle(.switch)
  - Two-column modifier hotkeys layout (Fast left, Slow right)
  - Dropdown (.menu) picker for modifier key selection
  - Window width increased to 520pt
  - Global hotkey recorder hint after 2 rejected attempts
- Moved scroll acceleration toggle from Advanced to General tab
- Scroll acceleration off: 2x base speed compensation
- Smoothness slider range fixed (0.2–1.0, was 0.0–0.5)
- Smoothness compensation curve: pow(ratio, 0.15) — gentle ramp
- Bug fixes from dual code review (internal + Gemini CLI):
  - passRetained → passUnretained (memory leak on passthrough events)
  - windowUnderCursor() dispatched to main thread in animationFrame
  - Profile smoothness/momentumDuration sync on slider change
  - Expanded NSLock scope to cover all mutable state
  - Modifier hotkeys now apply to horizontal scroll
  - Swipe acceleration reset on dt > swipeMaxInterval
  - Reverse scroll velocity zeroing uses effectiveDirection
  - animationTimer access protected by lock
  - Momentum window check throttled to ~10Hz

## Current Status
- v2.0 feature-complete (8/8)
- All code reviewed by dual subagents + Gemini CLI — no outstanding bugs
- Build succeeds
- All docs updated

## Next Actions
- [ ] Commit all changes
- [ ] Signed .app / .dmg distribution

## Open Questions
None

## Blockers
None
