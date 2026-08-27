#!/bin/bash
# Rewrite plugin-sources.json from git-managed third-party plugins
# installed under ~/.config/omarchy/plugins.
#
# Custom slim.* plugins are skipped (they are vendored in this repo).
# Checkouts with no origin remote are skipped with a warning.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCKFILE="$SCRIPT_DIR/plugin-sources.json"
PLUGINS_DIR="${OMARCHY_PLUGINS_DIR:-$HOME/.config/omarchy/plugins}"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Scan ~/.config/omarchy/plugins for git checkouts with an origin remote
and rewrite plugin-sources.json (sorted by id).

Options:
  -h        Show this help and exit
  -n        Dry run (print JSON, do not write)
EOF
  exit "${1:-0}"
}

while getopts ":hn" opt; do
  case "$opt" in
    h) usage 0 ;;
    n) DRY_RUN=1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage 2 ;;
  esac
done
shift $((OPTIND - 1))

entries='[]'

if [[ -d $PLUGINS_DIR ]]; then
  for dir in "$PLUGINS_DIR"/*/; do
    [[ -d $dir ]] || continue
    id="$(basename "$dir")"
    if [[ ! -d $dir/.git ]]; then
      continue
    fi
    url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
    if [[ -z $url ]]; then
      echo "dump-plugins: skipping '$id' (git checkout has no origin)" >&2
      continue
    fi
    entries="$(jq --arg id "$id" --arg url "$url" '. + [{id: $id, url: $url}]' <<<"$entries")"
  done
else
  echo "dump-plugins: plugins directory not found: $PLUGINS_DIR" >&2
fi

json="$(jq -n --argjson plugins "$entries" '{plugins: ($plugins | sort_by(.id))}')"
count="$(jq '.plugins | length' <<<"$json")"
if [[ $count -eq 0 ]]; then
  echo "dump-plugins: no git-managed plugins with an origin remote found" >&2
fi

if [[ $DRY_RUN -eq 1 ]]; then
  printf '%s\n' "$json"
  exit 0
fi

printf '%s\n' "$json" >"$LOCKFILE"
echo "Wrote $count plugin(s) to $LOCKFILE"
