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
