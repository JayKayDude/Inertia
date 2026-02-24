# Session State

> Updated each session. Tracks current position, blockers, and next actions.

## Last Updated
2026-02-23

## Current Phase
v2.0 — 6/8 features implemented, plus tabbed UI restructure

## What Was Done This Session
- Scroll acceleration toggle (disable speed curve for linear scrolling)
- Reverse scroll direction (per-axis vertical/horizontal toggles)
- Scroll distance multiplier with presets (Half/Default/Double/Triple)
- Tabbed settings window (General / Advanced / Preview tabs)
- Expanded live preview with 3 test areas (vertical, horizontal, combined)
- PreviewTextView extended to handle horizontal deltaX
- Settings window made resizable

## What Was Decided
- Tab order: General → Advanced → Preview (General opens first)
- General tab: Enable, Launch at Login, Speed, Smoothness, Reset
- Advanced tab: Acceleration toggle, Scroll Distance, Horizontal, Reverse, Modifier Hotkeys, Global Hotkey
- Preview tab: Three labeled scroll test areas (vertical-only, horizontal-only, both)
- Scroll acceleration toggle bypasses both speed curve AND fastScrollFactor
- Reverse direction applied via effectiveDirection in ScrollEngine.processScroll
- Scroll distance multiplier applied after speed curve, before modifier hotkeys
- Window resizable with .resizable styleMask, default 420x650

## Current Status
- 6/8 v2.0 features complete
- Tabbed UI restructure complete
- All changes committed (4 commits this session)
- Code reviewed by subagents and Gemini CLI — no bugs found

## Next Actions
- [ ] App blacklist — per-app disable with app picker UI
- [ ] Per-app scroll profiles — different speed/smoothness per app
- [ ] Signed .app / .dmg distribution

## Open Questions
None

## Blockers
None
