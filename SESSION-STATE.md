# Session State

> Updated each session. Tracks current position, blockers, and next actions.

## Last Updated
2026-02-20

## Current Phase
v0.8 — All phases implemented, settings streamlined, modifier hotkeys added

## What Was Decided
- Build from scratch in pure Swift/SwiftUI (not fork MMF)
- v0.8/v1.0 versioning split
- MMF presets: Slow/Medium/Fast speed + Low/Regular/High smoothness
- Both preset groups have Custom state when slider diverges
- Base Speed slider always visible below speed presets
- Smoothness slider (internally momentum duration) below smoothness presets
- Removed curve steepness setting (imperceptible effect, hardcoded c=1.5)
- Removed smoothness slider (imperceptible effect, compensation factor cancels it out)
- Momentum duration capped at 0.5 (was 2.0)
- Modifier hotkeys: Control=fast (2x), Option=slow (0.5x) by default, customizable
- Must use CGEventSource.flagsState(.combinedSessionState) for modifier detection (not event.flags)
- Enable/disable toggle in both menubar and settings window (custom Binding pattern)
- Event construction matches MMF: CGEvent(source: nil), field 55=22, three delta fields
- Direction-only rawDelta (magnitude ignored, like MMF)
- Half-life friction model with DispatchSourceTimer at 120Hz
- Thread safety via NSLock (replaced DispatchQueue.sync to avoid deadlocks)
- Enable/disable toggle uses custom Binding (not onChange)

## Current Status
- All v0.8 phases complete and functional
- Scroll engine working with MMF-matched physics
- Settings UI: enable toggle, speed presets + slider, smoothness presets + slider, modifier hotkeys
- Live preview panel operational
- Credits window with MMF and Freepik attribution
- Custom app icon and menubar icon

## Next Actions
- [ ] Further tune scroll feel to match MMF more closely
- [ ] Improve live preview to show momentum/inertia
- [ ] Signed .app / .dmg distribution
- [ ] v1.0 features: curve editor, per-app profiles

## Open Questions
None

## Blockers
None
