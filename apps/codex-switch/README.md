# codex-switch

**codex-switch** is a developer productivity script for working with Git branches and containerized dev environments.  
It automates the flow of:

1. Prompting you for a Git branch (defaults to the most recent pull request branch if available).
2. Switching to that branch.
3. Restarting your `docker compose` stack.
4. Waiting for all containers with healthchecks to become `healthy`.
5. Streaming a **live TUI** (spinner, progress bar, ETA, compact rolling logs, and healthy counters).
6. Automatically restoring your original branch when done.

This lets you preview any branch with its full runtime services in minutes, without polluting your current working tree.

---

## Features

- **Branch selection with smart defaults**:
  - Shows the most recent PR branch name (via `gh pr list`), dimmed as a placeholder.
  - If you type/paste a branch name, it uses your input. Pressing `Enter` accepts the placeholder.
- **Compose restart + health monitoring**:
  - Restarts all Compose services for the chosen branch.
  - Waits for all health-enabled containers to report `healthy` (with a configurable timeout).
- **Interactive TUI** (if running in a TTY):
  - Top header: spinner, branch name, progress bar, ETA, healthy counters.
  - Middle pane: compact rolling logs (default 8 rows, truncated lines).
  - Bottom footer: pending/unhealthy list + user hint.
  - Uses an alternate terminal screen for a clean experience.
- **Fallback plain logs** when not in a TTY (e.g. CI pipelines).
- **Safe restore**: always switches you back to your original branch on exit, even if aborted with `Ctrl+C`.
- **Clipboard opt-in**: if `CODEX_CLIP=1`, final output is copied to system clipboard (supports `pbcopy`, `xclip`, `xsel`).

---

## Requirements

- `git`
- `docker` + `docker compose` (or legacy `docker-compose`)
- Optional:
  - [`gh`](https://cli.github.com/) for auto-detecting recent PR branches
  - Clipboard tool (`pbcopy` on macOS, `xclip`/`xsel` on Linux)

---

## Installation

Save the script somewhere on your PATH (for example, under `scripts/` in your repo):

```bash
chmod +x /usr/local/bin/codex-switch

codex-switch
``` 

### {Variable} {Default} {Description}
```sh
CODEX_TIMEOUT 180 Max seconds to wait for health.
CODEX_POLL 1 Seconds between health checks.
CODEX_LOG_ROWS 8 Number of log rows shown in the live TUI.
CODEX_LOG_TAIL 80 How many log lines to seed from startup.
CODEX_LOG_CHARS 100 Max characters per log line (truncate after this).
CODEX_LOG_SERVICES (all) Comma-separated list of services to stream logs from.
CODEX_CLIP unset If set, copy summary output to clipboard.
```

### Example
`CODEX_TIMEOUT=300 CODEX_LOG_ROWS=10 CODEX_LOG_SERVICES="gateway-caddy,overlay-hub" /usr/local/bin//codex-switch`

```sh
$ codex-switch
Codex branch to switch to [feature/new-ingest-service]:
⠙ Compose health [======            ]  42%  2/4 healthy  ETA: ~65s
─ logs (last 8) ─────────────────────────────────────
gateway-caddy  | listening on :8080
overlay-hub    | booted successfully
capture-daemon | pulling driver module
...
pending: weaviate
``` 

### It’s designed as a switchboard for your dev system:
- Codex = knowledge/system baseline.
- Switch = safely change context, run services, and return home.

It removes the friction of testing branches in full service environments.
