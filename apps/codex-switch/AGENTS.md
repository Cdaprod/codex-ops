AGENTS.md

codex-switch Agent Guidelines

This document tells Codex how to continuously improve the codex-switch tool whenever it reads this directory.

⸻

Purpose

codex-switch is a Git + Docker Compose workflow helper. It allows developers to:
	•	Switch to a target branch (defaulting to most recent PR branch).
	•	Restart Compose services.
	•	Wait until all containers are healthy.
	•	Provide a live TUI with spinner, progress bar, ETA, compact log pane, and pending service status.
	•	Restore the original branch safely.

⸻

Improvement Priorities
	1.	Branch Selection UX
	•	Always prefer the most relevant PR branch as a placeholder.
	•	If gh is installed, fetch the newest PR branch name.
	•	Allow input override but show placeholder dimmed.
	•	Ensure non-interactive CI defaults gracefully.
	2.	TUI Feedback
	•	Keep logs short and signal-focused.
	•	Default: ~8 lines, max 100 chars per line, truncated with ellipsis.
	•	Always display header (progress bar + ETA) and footer (pending services).
	•	Maintain clean alternate-screen mode and restore cursor on exit.
	3.	Health Waiting
	•	Dynamically poll only containers with healthchecks.
	•	Show container names when pending/unhealthy.
	•	Print transition state changes as they occur.
	•	Respect configurable timeout and poll interval.
	4.	Logging Strategy
	•	Avoid overwhelming the user; seed logs with a small tail (default 80).
	•	Support CODEX_LOG_SERVICES to follow specific services.
	•	Provide concise, human-readable summaries when not in a TTY.
	5.	Resilience
	•	Always restore the original branch on exit (even after Ctrl+C).
	•	Handle errors gracefully if branch switching or Compose restart fails.
	•	Avoid breaking if no containers expose healthchecks.
	6.	Extensibility
	•	Environment variables should configure behavior:
	•	CODEX_TIMEOUT, CODEX_POLL, CODEX_LOG_ROWS, CODEX_LOG_TAIL, CODEX_LOG_CHARS, CODEX_CLIP.
	•	Ensure defaults are sensible but easily overridden.
	•	Add hooks for future extensions (metrics export, structured logging).

⸻

Coding Standards
	•	Portability: Must run on Linux and macOS.
	•	No hard dependencies beyond Git and Docker; gracefully degrade if gh or clipboard tools are missing.
	•	Idempotence: Running twice in a row should produce the same result without side effects.
	•	Compact Output: Favor clarity and brevity. Avoid flooding the screen with raw logs.

⸻

Future Enhancements
	•	Add CI integration mode (non-interactive, structured JSON output).
	•	Improve ETA calculation with per-service health check history.
	•	Optional "fast-fail" mode: stop early if any container reports unhealthy.
	•	Color-coded log highlighting for warnings/errors.
	•	Pluggable health strategies (not just Docker healthchecks).

⸻

Would you like me to also create a compact "manpage" style AGENTS.md (with NAME, DESCRIPTION, ENVIRONMENT, EXAMPLES, AUTHOR) so it doubles as both agent instructions and developer docs?