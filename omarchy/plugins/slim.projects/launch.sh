#!/bin/bash
set -euo pipefail

EDITOR_JSON="${1:-}"
PROJECT_PATH="${2:-}"
CONFIG="${HOME}/.config/omarchy/projects.json"

if [[ -z "$EDITOR_JSON" || -z "$PROJECT_PATH" ]]; then
  echo "usage: launch.sh <editor-json> <project-path>" >&2
  exit 1
fi

if ! jq -e 'type == "object"' <<<"$EDITOR_JSON" >/dev/null 2>&1; then
  EDITOR_JSON='{}'
fi

id="$(jq -r '.id // "cursor"' <<<"$EDITOR_JSON")"
kind="$(jq -r '.kind // "gui"' <<<"$EDITOR_JSON")"
class="$(jq -r '.class // empty' <<<"$EDITOR_JSON")"
project_name="$(basename -- "$PROJECT_PATH")"

command=()
while IFS= read -r part; do
  [[ -n "$part" ]] && command+=("$part")
done < <(jq -r '.command[]? // empty' <<<"$EDITOR_JSON")

if [[ ${#command[@]} -eq 0 && -f "$CONFIG" ]]; then
  while IFS= read -r part; do
    [[ -n "$part" ]] && command+=("$part")
  done < <(jq -r --arg id "$id" '.editors[]? | select(.id == $id) | .command[]? // empty' "$CONFIG")
  if [[ -z "$kind" || "$kind" == "gui" ]]; then
    kind="$(jq -r --arg id "$id" '.editors[]? | select(.id == $id) | .kind // "gui"' "$CONFIG")"
  fi
  if [[ -z "$class" ]]; then
    class="$(jq -r --arg id "$id" '.editors[]? | select(.id == $id) | .class // empty' "$CONFIG")"
  fi
fi

if [[ "$id" == "omarchy" || "$kind" == "omarchy" ]]; then
  setsid omarchy-launch-editor "$PROJECT_PATH" </dev/null >/dev/null 2>&1 &
  exit 0
fi

if [[ ${#command[@]} -eq 0 ]]; then
  command=("$id")
fi

# ~/.local/bin/cursor is a CLI shim that looks up the IDE on PATH. Hypr/UWSM
# launches often miss /usr/bin, so the shim fails or opens agent/glass mode.
bin="${command[0]}"
base="$(basename -- "$bin")"
if [[ "$id" == "cursor" || "$base" == "cursor" ]]; then
  if [[ -x /usr/bin/cursor ]]; then
    command[0]="/usr/bin/cursor"
  elif [[ -x /usr/share/cursor/cursor ]]; then
    command[0]="/usr/share/cursor/cursor"
  fi
  has_classic=0
  for arg in "${command[@]:1}"; do
    if [[ "$arg" == "--classic" ]]; then
      has_classic=1
      break
    fi
  done
  if (( has_classic == 0 )); then
    command+=("--classic")
  fi
  [[ -n "$class" ]] || class="cursor"
fi

if [[ "${SLIM_PROJECTS_DRY_RUN:-}" == 1 ]]; then
  printf '%q ' "${command[@]}" "$PROJECT_PATH"
  printf '\n'
  exit 0
fi

if [[ "$kind" == "tui" ]]; then
  setsid omarchy-launch-tui "${command[@]}" "$PROJECT_PATH" </dev/null >/dev/null 2>&1 &
  exit 0
fi

if [[ ! -x "${command[0]}" ]] && ! command -v "${command[0]}" >/dev/null 2>&1; then
  notify-send "Projects" "Editor not found: ${command[0]}"
  exit 1
fi

# Foreground uwsm-app hangs when spawned from Hypr/Quickshell; detach instead.
setsid uwsm-app -- "${command[@]}" "$PROJECT_PATH" </dev/null >/dev/null 2>&1 &

if [[ -z "$class" ]]; then
  exit 0
fi

addr=""
for _ in {1..30}; do
  addr="$(hyprctl clients -j | jq -r --arg n "$project_name" --arg c "$class" '
    [.[] | select((.class | test($c; "i")) and (.title | test($n; "i"))) | .address] | first // empty
  ')"
  if [[ -n "$addr" ]]; then
    hyprctl dispatch focuswindow "address:${addr}" >/dev/null 2>&1 || true
    exit 0
  fi
  sleep 0.1
done

hyprctl dispatch focuswindow "class:${class}" >/dev/null 2>&1 || true
