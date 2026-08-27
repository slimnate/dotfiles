#!/bin/bash
set -euo pipefail

CONFIG="${1:-$HOME/.config/omarchy/projects.json}"
HOME_DIR="${HOME}"
BRANCH_MAX="${BRANCH_MAX:-24}"

expand_path() {
  local p="$1"
  if [[ "$p" == "~" ]]; then
    printf '%s\n' "$HOME_DIR"
  elif [[ "$p" == '~/'* ]]; then
    printf '%s\n' "$HOME_DIR/${p:2}"
  else
    printf '%s\n' "$p"
  fi
}

one_line() {
  printf '%s' "$1" | tr '\r\n\t' '   '
}

latest_mtime() {
  local path="$1"
  local ts
  ts="$(find -L "$path" \
      -path "$path/.git" -prune -o \
      -path "$path/node_modules" -prune -o \
      -type f -printf '%T@\n' 2>/dev/null | sort -nr | head -1 || true)"
  if [[ -z "${ts:-}" ]]; then
    stat -c %Y "$path" 2>/dev/null || echo 0
  else
    printf '%.0f\n' "$ts"
  fi
}

humanize_epoch() {
  local t="$1"
  local now diff
  now="$(date +%s)"
  diff=$(( now - t ))
  if (( diff < 60 )); then
    echo "${diff}s ago"
  elif (( diff < 3600 )); then
    echo "$(( diff / 60 ))m ago"
  elif (( diff < 86400 )); then
    echo "$(( diff / 3600 ))h ago"
  else
    echo "$(( diff / 86400 ))d ago"
  fi
}

project_json() {
  local path="$1"
  local name="$2"
  local editor="$3"

  local ts human branch dirty ahead behind tags
  tags=""

  [[ -f "$path/package.json" ]] && tags+="node "
  [[ -f "$path/pnpm-lock.yaml" ]] && tags+="pnpm "
  [[ -f "$path/yarn.lock" ]] && tags+="yarn "
  [[ -f "$path/bun.lockb" ]] && tags+="bun "
  [[ -f "$path/go.mod" ]] && tags+="go "
  [[ -f "$path/pyproject.toml" || -f "$path/requirements.txt" ]] && tags+="python "
  [[ -f "$path/Cargo.toml" ]] && tags+="rust "
  [[ -f "$path/composer.json" ]] && tags+="php "
  [[ -f "$path/.tool-versions" || -f "$path/.mise.toml" ]] && tags+="mise "
  [[ -d "$path/.devcontainer" ]] && tags+="devcontainer "
  [[ -f "$path/Dockerfile" || -f "$path/docker-compose.yml" ]] && tags+="docker "
  [[ -d "$path/tests" || -d "$path/test" ]] && tags+="tests "
  tags="${tags%% }"

  ts="$(latest_mtime "$path")"
  human="$(humanize_epoch "$ts")"

  if git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    branch="$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    branch="$(one_line "${branch:--}")"
    if [[ -n "$branch" && "$branch" != "-" ]]; then
      if (( ${#branch} > BRANCH_MAX )); then
        branch="${branch:0:$((BRANCH_MAX-1))}…"
      fi
    fi
    dirty="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | awk '{print $1}' || true)"
    dirty="${dirty:-0}"
    ahead=0
    behind=0
    if git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
      counts="$(git -C "$path" rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null || true)"
      ahead="$(awk '{print $1}' <<<"${counts:-0 0}")"
      behind="$(awk '{print $2}' <<<"${counts:-0 0}")"
    fi
    ahead="${ahead:-0}"
    behind="${behind:-0}"
  else
    branch="-"
    dirty="0"
    ahead="0"
    behind="0"
  fi

  jq -nc \
    --argjson ts "$ts" \
    --arg name "$(one_line "$name")" \
    --arg path "$(one_line "$path")" \
    --arg branch "$(one_line "$branch")" \
    --argjson dirty "${dirty:-0}" \
    --argjson ahead "${ahead:-0}" \
    --argjson behind "${behind:-0}" \
    --arg activity "$(one_line "$human")" \
    --arg tags "$(one_line "$tags")" \
    --arg editor "$(one_line "$editor")" \
    '{ts:$ts, name:$name, path:$path, branch:$branch, dirty:$dirty, ahead:$ahead, behind:$behind, activity:$activity, tags:$tags, editor:$editor}'
}

declare -a BASE_DIRS=()
declare -A LABEL_FOR_PATH=()
declare -A EDITOR_FOR_PATH=()
declare -a PINNED_PATHS=()

if [[ -f "$CONFIG" ]]; then
  while IFS= read -r dir; do
    [[ -n "$dir" ]] || continue
    BASE_DIRS+=("$(expand_path "$dir")")
  done < <(jq -r '.baseDirs[]? // empty' "$CONFIG")

  while IFS=$'\t' read -r label path editor; do
    [[ -n "$path" ]] || continue
    path="$(expand_path "$path")"
    [[ -d "$path" ]] || continue
    PINNED_PATHS+=("$path")
    [[ -n "$label" ]] && LABEL_FOR_PATH["$path"]="$label"
    [[ -n "$editor" ]] && EDITOR_FOR_PATH["$path"]="$editor"
  done < <(jq -r '.projects[]? | [(.label // ""), (.path // ""), (.editor // "")] | @tsv' "$CONFIG")
else
  BASE_DIRS=("$HOME_DIR/Documents/dev")
  PINNED_PATHS+=("$HOME_DIR/.dotfiles" "/usr/share/omarchy" "$HOME_DIR/.openclaw")
  LABEL_FOR_PATH["$HOME_DIR/.dotfiles"]="Custom Dotfiles"
  LABEL_FOR_PATH["/usr/share/omarchy"]="Omarchy Config"
  LABEL_FOR_PATH["$HOME_DIR/.openclaw"]="OpenClaw Config"
fi

declare -A SEEN=()
declare -a PATHS=()

for dir in "${BASE_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    if [[ -n "${SEEN[$path]+x}" ]]; then
      continue
    fi
    SEEN["$path"]=1
    PATHS+=("$path")
  done < <(find -L "$dir" -mindepth 1 -maxdepth 1 -type d -print)
done

for path in "${PINNED_PATHS[@]}"; do
  [[ -d "$path" ]] || continue
  if [[ -z "${SEEN[$path]+x}" ]]; then
    SEEN["$path"]=1
    PATHS+=("$path")
  fi
done

{
  for path in "${PATHS[@]}"; do
    name="$(basename -- "$path")"
    if [[ -n "${LABEL_FOR_PATH[$path]+x}" ]]; then
      name="${LABEL_FOR_PATH[$path]}"
    fi
    editor="${EDITOR_FOR_PATH[$path]:-}"
    project_json "$path" "$name" "$editor" || true
  done
} | jq -s 'sort_by(-.ts)'
