# Session State

> Updated each session. Tracks current position, blockers, and next actions.

## Last Updated
2026-02-20

## Current Phase
v0.8 — All phases implemented, tuning scroll feel

## What Was Decided
- Build from scratch in pure Swift/SwiftUI (not fork MMF)
- v0.8/v1.0 versioning split
- MMF presets: Slow/Medium/Fast speed + Low/Regular/High smoothness (Off removed)
- Base Speed slider always visible, Advanced section expandable
- Preset ↔ slider sync with "Custom" label
- Event construction matches MMF: CGEvent(source: nil), field 55=22, three delta fields
- Direction-only rawDelta (magnitude ignored, like MMF)
- Half-life friction model instead of CVDisplayLink
- Thread safety via NSLock (replaced DispatchQueue.sync to avoid deadlocks)
- Removed minTickSize (dead code)
- Enable/disable toggle uses custom Binding (not onChange, which doesn't fire for @AppStorage on classes)

## Current Status
- All v0.8 phases complete and functional
- Scroll engine working with MMF-matched physics
- Settings UI with presets and advanced sliders
- Live preview panel operational
- Enable/disable toggle fixed
- First commit pushed to GitHub

## Next Actions
- [ ] Further tune scroll feel to match MMF more closely
- [ ] Consider recalibrating preset pixel values to MMF ranges
- [ ] Improve live preview to show momentum/inertia
- [ ] v1.0 features: curve editor, per-app profiles

## Open Questions
- Should preset pixel-per-tick values be recalibrated to match MMF exactly?

## Blockers
None
