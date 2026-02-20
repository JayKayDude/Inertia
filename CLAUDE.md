# Inertia — Project Instructions for Claude

## Project Overview
**Inertia** is a macOS menubar app that replaces stepped mouse wheel scrolling with smooth, physics-based inertial scrolling. Built from scratch in Swift/SwiftUI, using Mac Mouse Fix's physics formulas as reference.

## Repository
- **Branch:** `main` (primary working branch)
- **Platform:** macOS (Darwin), zsh shell
- **Environment:** iCloud Drive / VS Code + Xcode
- **Language:** Swift 5.9+, SwiftUI
- **Deployment target:** macOS 15.0 (Sequoia)
- **Bundle ID:** `com.jaykecollier.Inertia`

## Tech Stack
- **UI:** SwiftUI (`MenuBarExtra`, settings window)
- **Scroll interception:** `CGEventTap` at `kCGHIDEventTap`
- **Display sync:** `CVDisplayLink` for smooth momentum animation
- **Persistence:** `@AppStorage` / `UserDefaults`
- **Mouse vs trackpad:** `kCGScrollWheelEventIsContinuous` (0 = mouse, 1 = trackpad passthrough)

## MMF Reference
- Physics formulas adapted from Mac Mouse Fix by Noah Nuebling
- Speedup curve: `y = a * pow(b, (x-t) * c) + 1 - a`
- Inertia is a derivative work with substantial changes (new UI, rewritten engine, free/open source)
- Must attribute MMF prominently in UI and README

## Coding Standards
- Prefer editing existing files over creating new ones
- Keep solutions minimal — no over-engineering
- Do not add comments, docstrings, or type annotations unless explicitly requested
- Avoid backwards-compatibility shims; delete unused code outright
- Validate only at system boundaries (user input, external APIs)

## Build
- Open `Inertia.xcodeproj` in Xcode
- Build target: "Inertia" (macOS app)
- Requires Accessibility permission at runtime

## Workflow
- Read files before modifying them
- Confirm before any destructive git operation (force push, reset --hard, etc.)
- Do NOT auto-commit — only commit when the user explicitly asks
- Do NOT push to remote unless explicitly requested

## Memory & Context
- Check `/Users/jaykecollier/.claude/projects/-Users-jaykecollier/memory/MEMORY.md` for cross-session notes
- Update `SESSION-STATE.md` at natural stopping points
- Record architectural decisions in `PROJECT-MEMORY.md`
- Log recurring problems and solutions in `LEARNING-LOG.md`

## AI Governance
- Evaluate governance before non-trivial actions
- Skip governance checks only for: file reads, searches, trivial formatting
- S-Series safety principles have veto authority — always escalate if triggered
