#!/usr/bin/env bash
# codex-switch -- prompt for a branch, switch, restart compose, wait for HEALTH,
# render a live TUI (spinner + progress bar + counters), then ALWAYS return
# to the original branch. Clipboard is OPT-IN with CODEX_CLIP=1.
#
# Works in both macOS & Linux. Falls back to plain logs if not a TTY.

set -uo pipefail

# ------------------------ utils ------------------------
have()      { command -v "$1" >/dev/null 2>&1; }
now()       { date +"%Y-%m-%d %H:%M:%S"; }
is_tty()    { [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && [[ "${TERM:-dumb}" != "dumb" ]]; }
dim()       { printf "\033[2m%s\033[0m" "$*"; }
green()     { printf "\033[32m%s\033[0m" "$*"; }
yellow()    { printf "\033[33m%s\033[0m" "$*"; }
red()       { printf "\033[31m%s\033[0m" "$*"; }
clearline() { printf "\r\033[K"; }   # CR + clear-to-eol

# Choose docker compose CLI
dc() { have docker-compose && docker-compose "$@" || docker compose "$@"; }

# Clipboard is opt-in to avoid DISPLAY issues (set CODEX_CLIP=1 to enable)
clipboard_sink() {
  if [ -n "${CODEX_CLIP:-}" ]; then
    if have pbcopy; then pbcopy
    elif [ -n "${DISPLAY:-}" ] && have xclip; then xclip -selection clipboard
    elif [ -n "${DISPLAY:-}" ] && have xsel;  then xsel --clipboard --input
    else cat
    fi
  else
    cat
  fi
}

# ------------------------ TUI helpers ------------------------
SPIN_FRAMES='-\|/'
spin_idx=0
spinner_tick() {
  # prints one spinner frame without newline
  local ch
  ch="${SPIN_FRAMES:spin_idx%${#SPIN_FRAMES}:1}"
  printf "%s" "$ch"
  spin_idx=$((spin_idx+1))
}

progress_bar() {
  # $1=current  $2=total  $3=width
  local cur=$1 total=$2 width=${3:-32}
  (( total <= 0 )) && total=1
  local pct=$(( 100 * cur / total ))
  local fill=$(( width * cur / total ))
  local rest=$(( width - fill ))
  printf "[%.*s%*s] %3d%%" "$fill" "########################################" "$rest" "" "$pct"
}

# render a dynamic status line: spinner + title + progress + counters + details
render_line() {
  # $1=title  $2=elapsed  $3=timeout  $4=ok  $5=total  $6=unhealthy_csv
  local title="$1" elapsed=$2 timeout=$3 ok=$4 total=$5 list="$6"
  clearline
  printf " "
  spinner_tick
  printf " %s " "$(dim "$title")"
  progress_bar "$elapsed" "$timeout" 24
  printf "  %s/%s %s" "$(green "$ok")" "$total" "$(dim healthy)"
  if [ -n "$list" ]; then
    printf "  %s %s" "$(yellow "pending:")" "$(dim "$list")"
  fi
}

newline_once() { printf "\n"; }

# ------------------------ health logic ------------------------
# Builds a list of compose container IDs that actually have Health
compose_health_ids() {
  local ids
  ids="$(dc ps -q || true)"
  [ -z "$ids" ] && return 0
  for id in $ids; do
    if docker inspect -f '{{if .State.Health}}yes{{end}}' "$id" 2>/dev/null | grep -q yes; then
      printf "%s\n" "$id"
    fi
  done
}

# Wait until all health-enabled containers are healthy (or timeout).
wait_for_health_tui() {
  # $1 timeout(s)  $2 poll(s)
  local timeout="${1:-180}" poll="${2:-1}"
  local start end elapsed
  local -a ids
  mapfile -t ids < <(compose_health_ids)
  local total="${#ids[@]}"

  if (( total == 0 )); then
    echo "$(now) [INFO] No containers with healthchecks; skipping health wait."
    return 0
  fi

  if is_tty; then
    echo "$(now) [INFO] Waiting for ${total} container(s) to become healthy…"
  else
    echo "$(now) [INFO] Waiting (no TTY, plain logs)…"
  fi

  start="$(date +%s)"
  local -A LAST=()
  local ok not_ok id name hstate cstate
  local pending_csv

  while :; do
    end="$(date +%s)"; elapsed=$(( end - start ))
    ok=0; not_ok=0; pending_csv=""

    for id in "${ids[@]}"; do
      # name, health, state
      read -r name hstate cstate < <(docker inspect -f '{{.Name}} {{.State.Health.Status}} {{.State.Status}}' "$id" 2>/dev/null | sed 's#^/##')
      hstate="${hstate:-none}"; cstate="${cstate:-unknown}"

      # transition logs (only when it changes)
      if [[ "${LAST[$id]:-}" != "$hstate/$cstate" ]]; then
        if ! is_tty; then
          echo "$(now) [HEALTH] $name => health=$hstate state=$cstate (t+${elapsed}s)"
        fi
        LAST[$id]="$hstate/$cstate"
      fi

      if [[ "$hstate" == "healthy" ]]; then
        ok=$((ok+1))
      else
        not_ok=$((not_ok+1))
        pending_csv+="${name},"
      fi
    done

    # Trim trailing comma
    pending_csv="${pending_csv%,}"

    if is_tty; then
      render_line "Health check" "$elapsed" "$timeout" "$ok" "$total" "$pending_csv"
    else
      # plain, less noisy summary every 3s
      if (( elapsed % 3 == 0 )); then
        echo "$(now) [WAIT] ${ok}/${total} healthy (pending: ${pending_csv:-none})"
      fi
    fi

    if (( not_ok == 0 )); then
      if is_tty; then newline_once; fi
      echo "$(now) [OK] All containers healthy in ${elapsed}s."
      return 0
    fi

    if (( elapsed >= timeout )); then
      if is_tty; then newline_once; fi
      echo "$(now) [TIMEOUT] ${not_ok} container(s) not healthy after ${elapsed}s: ${pending_csv:-none}"
      return 2
    fi

    sleep "$poll"
  done
}

show_unhealthy_logs() {
  local tail="${1:-80}"
  local ids id name hstate cstate
  ids="$(dc ps -q || true)"
  [ -z "$ids" ] && return 0
  for id in $ids; do
    read -r name hstate cstate < <(docker inspect -f '{{.Name}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} {{.State.Status}}' "$id" 2>/dev/null | sed 's#^/##')
    if [[ "$hstate" != "healthy" ]] && [[ "$hstate" != "none" ]]; then
      echo
      echo "$(now) [LOGS] === $name (health=$hstate state=$cstate) ==="
      docker logs --tail "$tail" "$id" 2>&1 || true
    fi
  done
}


# ------------------------ branch selection ------------------------
recent_pr_branch() {
  local b=""
  if have gh; then
    b="$(gh pr list --state open --limit 1 --sort updated --json headRefName -q '.[0].headRefName' 2>/dev/null || true)"
    if [[ -z "$b" ]]; then
      b="$(gh pr list --state all --limit 1 --sort updated --json headRefName -q '.[0].headRefName' 2>/dev/null || true)"
    fi
  fi
  if [[ -z "$b" ]]; then
    b="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  fi
  printf "%s" "$b"
}

# ------------------------ main flow ------------------------
main() {
  local ORIG PLACEHOLDER BRANCH INPUT OUT
  ORIG="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  PLACEHOLDER="$(recent_pr_branch)"
  if is_tty; then
    read -rp "Codex branch to switch to [$(dim "$PLACEHOLDER")]: " INPUT || INPUT=""
    BRANCH="${INPUT:-$PLACEHOLDER}"
  else
    BRANCH="$PLACEHOLDER"
    echo "$(now) [INFO] Non-interactive; using branch: $BRANCH"
  fi

  OUT="$(mktemp -t codex-switch.XXXXXX)"

  restore() {
    {
      echo "$(now) [INFO] Restoring original branch: $ORIG"
      if git switch -q "$ORIG" 2>/dev/null; then
        echo "$(now) [OK] Back on $ORIG"
      else
        echo "$(now) [WARN] Could not return to $ORIG; check your working tree." >&2
      fi
    } >>"$OUT" 2>&1
  }
  trap restore EXIT

  {
    echo "$(now) [INFO] Original branch: $ORIG"
    echo "$(now) [INFO] Switching to branch: $BRANCH"

    if git switch "$BRANCH"; then
      echo "$(now) [INFO] Restarting containers…"
      if dc restart; then
        wait_for_health_tui "${CODEX_TIMEOUT:-180}" "${CODEX_POLL:-1}"
        echo "$(now) [INFO] Inspecting unhealthy services (if any)…"
        show_unhealthy_logs "${CODEX_LOG_TAIL:-80}"
      else
        echo "$(now) [WARN] Compose restart failed."
      fi
    else
      echo "$(now) [ERROR] git switch \"$BRANCH\" failed."
    fi
  } >>"$OUT" 2>&1

  if clipboard_sink <"$OUT"; then :; else cat "$OUT"; fi
  rm -f "$OUT" || true
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
