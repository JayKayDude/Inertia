# Learning Log

> Recurring problems, root causes, and proven solutions. Add entries as issues are encountered and resolved.

## Format
```
### [Date] — Problem Title
**Symptom:** What went wrong or what was confusing
**Root Cause:** Why it happened
**Solution:** What fixed it
**Prevention:** How to avoid it in the future
```

---

## Entries

### 2026-02-18 — AI Governance MCP path error
**Symptom:** `evaluate_governance` and `query_governance` return "Log path must be within project root, home, or temp directory"
**Root Cause:** Docker container used `__file__`-based path resolution which resolves to site-packages inside Docker, not the project root
**Solution:** Updated MCP server Docker image (`docker pull jason21wc/ai-governance-mcp:latest`) — fix uses CWD-based root detection. Requires Claude Code restart after pull.
**Prevention:** After pulling new MCP Docker images, always restart Claude Code so the new container is used.

### 2026-02-19 — MMF codebase too complex to fork
**Symptom:** Planned to fork/extract MMF scroll engine files directly
**Root Cause:** MMF is primarily Obj-C with deep internal dependencies, making extraction into a clean Swift project impractical
**Solution:** Build from scratch in pure Swift, using MMF's physics formulas as reference only
**Prevention:** Always evaluate dependency depth before planning extraction from foreign codebases

### 2026-02-20 — Terminal scrolling 10x too fast
**Symptom:** Scrolling in Terminal.app was extremely fast while other apps were fine
**Root Cause:** `FixedPtDeltaAxis1` was set to raw pixel value. Terminal reads this field as a LINE delta (16.16 fixed-point). So 15 pixels → 15 lines × 10px = 150 pixels (10x too fast).
**Solution:** Set `FixedPtDeltaAxis1 = (pixels / pixelsPerLine) * 65536` — line delta in 16.16 fixed-point, not pixel delta. Also set all three delta fields consistently from the same rounded pixel value.
**Prevention:** Always set all three scroll event delta fields (DeltaAxis1, PointDeltaAxis1, FixedPtDeltaAxis1) consistently. Different apps read different fields. Match MMF's exact event construction.

### 2026-02-20 — Speed curve b=2.0 way too aggressive
**Symptom:** Scrolling fast caused extreme speed jumps
**Root Cause:** Using b=2.0 in speed curve when MMF uses b=1.1. Exponential base of 2.0 grows much faster than 1.1.
**Solution:** Changed to b=1.1 matching MMF, capped multiplier at 3.0
**Prevention:** Always use MMF's exact constants (b=1.1, p=1.33, t=8) as baseline

### 2026-02-20 — MMF speed curve formula inverts at low curveExponent
**Symptom:** Lowering Curve Steepness to 0.5 made the curve STEEPER, not flatter
**Root Cause:** The `a` coefficient = `(p-1)/(b^c - 1)`. At c=0.5, denominator is tiny (0.0488), so a=6.76 — hugely amplifying the curve.
**Solution:** Left MMF formula as-is (it works well at default c=1.5). User can adjust but extreme low values have this known behavior.
**Prevention:** Document the valid range. Consider alternative curve formulations for v1.0 curve editor.

### 2026-02-20 — DispatchQueue.sync caused deadlocks
**Symptom:** App would hang/freeze when scrolling
**Root Cause:** `animationFrame()` on animationQueue calls `postScrollEvent()` → `CGEvent.post()` which can dispatch to main thread. If main thread is blocked on `animationQueue.sync` (from stop() or handleScrollEvent), deadlock occurs.
**Solution:** Replaced `DispatchQueue` with `NSLock` for thread safety. Lock is held briefly for state access only, not during CGEvent.post().
**Prevention:** Never use sync dispatch queues when the queued work might need to access the calling thread. Use NSLock for fine-grained synchronization.

### 2026-02-20 — @AppStorage onChange doesn't fire on ObservableObject
**Symptom:** Enable/disable toggle in menubar didn't start/stop the scroll engine
**Root Cause:** `@AppStorage` on a class (ObservableObject) writes to UserDefaults but doesn't call `objectWillChange.send()`. SwiftUI's `.onChange` modifier never fires because it doesn't detect the change.
**Solution:** Replace `$config.enabled` + `.onChange` with a custom `Binding(get:set:)` that calls `engine.start()`/`engine.stop()` directly in the setter.
**Prevention:** Never rely on `.onChange` for `@AppStorage` properties on ObservableObject classes. Use custom Bindings or move `@AppStorage` into the View struct.

### 2026-02-20 — HID scroll events don't carry modifier key flags
**Symptom:** Modifier hotkeys (Control for fast scroll, Option for slow) had no effect when held during scrolling
**Root Cause:** Scroll wheel events intercepted at `kCGHIDEventTap` don't have keyboard modifier flags populated in `event.flags`
**Solution:** Use `CGEventSource.flagsState(.combinedSessionState)` to query the system-wide modifier key state instead of reading `event.flags`
**Prevention:** Always use `CGEventSource.flagsState(.combinedSessionState)` for modifier key detection in CGEventTap callbacks, not the event's own flags property

### 2026-02-20 — Curve steepness slider had no perceptible effect
**Symptom:** Changing the Curve Steepness slider (curveExponent) didn't visibly change scroll behavior
**Root Cause:** The `a` coefficient in the speed curve formula recalibrates when `c` changes, so the curve always passes through (t+1, 1.33) regardless of `c`. The 3x cap also kicks in quickly at all values.
**Solution:** Removed the setting entirely; hardcoded c=1.5
**Prevention:** Test settings across their full range to verify perceptible effect before exposing them in UI

### 2026-02-20 — Smoothness slider had no perceptible effect
**Symptom:** Changing the smoothness value didn't visibly change scroll feel
**Root Cause:** The compensation factor (`(1 - smoothness) / (1 - 0.9)`) scales the impulse inversely to smoothness, keeping total scroll distance constant. At typical mouse tick rates (5–20Hz), the blending difference between ticks is too subtle to perceive.
**Solution:** Removed the smoothness slider from UI; momentum duration is the meaningful control for perceived smoothness
**Prevention:** When two settings are coupled by a compensation formula, verify that the perceptual difference is actually noticeable

### 2026-02-20 — Git repo root was home directory
**Symptom:** `git status` showed thousands of untracked files from entire home directory. Commit included VEX Pathfinder files.
**Root Cause:** `.git` folder was at `/Users/jaykecollier/` (leftover from another project), not inside the Inertia folder.
**Solution:** Initialized fresh `git init` inside the Inertia folder. Force pushed clean commit to GitHub.
**Prevention:** Always check `git rev-parse --show-toplevel` before committing. Ensure `.git` is in the project root, not a parent directory.
