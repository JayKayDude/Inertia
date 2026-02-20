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
- Speedup curve: `y = a * pow(b, (x-t) * c) + 1 - a`
- Language: Swift 5.9+
- UI: SwiftUI
- Editor: VS Code + Claude Code + Xcode

## Architectural Decisions

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2026-02-18 | Governance docs created at project root | Standard AI governance initialization | Active |
| 2026-02-18 | Menubar-only app, no Dock icon | Lightweight background utility pattern | Active |
| 2026-02-18 | Intercept mouse wheel events only, leave trackpads alone | Trackpads already have system-level inertia | Active |
| 2026-02-19 | **Build from scratch, not fork MMF** | MMF is Obj-C with deep dependencies; clean Swift rewrite is simpler than extraction | Active |
| 2026-02-19 | **v0.8/v1.0 versioning** | v0.8 = working app (engine + UI + presets), v1.0 = adds curve editor + per-app profiles | Active |
| 2026-02-19 | **MMF presets: Slow/Medium/Fast speed + Off/Low/Regular/High smoothness** | Matches MMF's proven UX | Active |
| 2026-02-19 | **Base Speed slider always visible, Advanced section expandable** | Most users only need one slider; power users get the rest | Active |
| 2026-02-19 | **Preset ↔ slider sync with "Custom" label** | Selecting preset moves slider; dragging away shows Custom | Active |

## Versioning

### v0.8 — Working App
- Scroll engine (CGEventTap + CVDisplayLink + MMF physics)
- Menubar with enable toggle
- Settings window with presets, sliders, live preview
- Accessibility permission prompt

### v1.0 — Full Release
- Visual draggable curve editor (Bezier control points)
- Per-app scroll profiles
- Import/export settings
- App icon, signed distribution, Homebrew tap

## Constraints
- iCloud Drive sync — avoid large binary files or rapid file churn
- macOS-only (Darwin 25.3.0 dev environment)
- CGEventTap requires Accessibility permission from user on first launch

## Phase History
| Phase | Description | Completed |
|-------|-------------|-----------|
| Init  | Governance scaffolding, GitHub repo, project docs | 2026-02-18 |
| 0     | Documentation update for finalized plan | — |
| 1     | Project setup & menubar shell | — |
| 2     | Scroll engine core | — |
| 3     | Configuration & presets | — |
| 4     | Settings window | — |
| 5     | Live preview panel | — |

## Key File Locations
| File | Purpose |
|------|---------|
| `Inertia/InertiaApp.swift` | App entry, MenuBarExtra |
| `Inertia/ScrollEngine.swift` | CGEventTap, velocity, momentum, curves |
| `Inertia/ScrollConfig.swift` | Parameters, presets, @AppStorage |
| `Inertia/AccessibilityManager.swift` | Permission check & prompt |
| `Inertia/SettingsView.swift` | Main settings window |
| `Inertia/LivePreviewView.swift` | Scrollable preview panel |
| `CLAUDE.md` | Standing instructions for Claude Code |
| `SESSION-STATE.md` | Per-session progress tracker |
| `PROJECT-MEMORY.md` | This file — decisions and context |
| `LEARNING-LOG.md` | Recurring problems and solutions |
| `README.md` | Public-facing project description |
| `ROADMAP.md` | Detailed development roadmap |
