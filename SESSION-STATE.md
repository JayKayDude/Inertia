# Session State

> Updated each session. Tracks current position, blockers, and next actions.

## Last Updated
2026-02-23

## Current Phase
v2.0 — Three initial features implemented (launch at login, horizontal scrolling, global toggle hotkey)

## What Was Decided
- Horizontal scrolling: single-axis events without scroll phases (matches MMF continuous scroll mode)
- No phase-ended/began on axis switch — gesture lifecycle shared across axes (matches MOS approach)
- Event construction: CGEvent(source: nil), field 55=22, isContinuous=1, no scroll phase fields
- Shift removed from ModifierKey enum (conflicts with horizontal scroll)
- Modifier hotkeys excluded from horizontal scrolling (Shift conflict)
- Fast scroll acceleration resets on direction reversal and axis switch
- Velocity threshold lowered to 30.0 (was 120.0) for visible momentum on slow scrolls
- Carbon RegisterEventHotKey for global hotkey, with ID verification in callback
- SMAppService for launch at login (reads system status, no local state)

## Current Status
- All three initial v2.0 features complete and functional
- Code reviewed by internal subagent and Gemini CLI
- Bug fixes applied: passRetained→passUnretained (memory leak), onDisappear for HotkeyRecorderView, hotkey callback ID verification
- Debug logging stripped
- Documents updated

## Next Actions
- [ ] App blacklist — per-app disable
- [ ] Scroll distance multiplier
- [ ] Reverse scroll direction per-axis
- [ ] Scroll acceleration toggle
- [ ] Per-app scroll profiles
- [ ] Signed .app / .dmg distribution

## Open Questions
None

## Blockers
None
