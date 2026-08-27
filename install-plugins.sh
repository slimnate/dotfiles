#!/bin/bash
# Clone third-party Omarchy shell plugins listed in plugin-sources.json.
# Does not enable plugins; bar layout and enablement live in shell.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCKFILE="$SCRIPT_DIR/plugin-sources.json"
PLUGINS_DIR="${OMARCHY_PLUGINS_DIR:-$HOME/.config/omarchy/plugins}"
VERBOSE=0
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Clone missing third-party plugins from plugin-sources.json using
\`omarchy plugin add <url> --yes\`. Already-installed ids are skipped.
Plugins are not enabled; stowed shell.json owns bar placement.

Options:
  -h        Show this help and exit
  -v        Verbose output
  -n        Dry run (print commands instead of executing)
EOF
  exit "${1:-0}"
}

while getopts ":hvn" opt; do
  case "$opt" in
    h) usage 0 ;;
    v) VERBOSE=1 ;;
    n) DRY_RUN=1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage 2 ;;
  esac
done
shift $((OPTIND - 1))

run() { if [[ $DRY_RUN -eq 1 ]]; then echo "+ $*"; else "$@"; fi; }
log() { [[ $VERBOSE -eq 1 ]] && echo "$*"; }

if [[ ! -f $LOCKFILE ]]; then
  echo "install-plugins: lockfile not found: $LOCKFILE" >&2
  exit 1
fi

if ! jq -e '.plugins | type == "array"' "$LOCKFILE" >/dev/null; then
  echo "install-plugins: $LOCKFILE must contain a plugins array" >&2
  exit 1
fi

added=0
skipped=0
failed=0

while IFS=$'\t' read -r id url; do
  [[ -n $id && -n $url ]] || continue
  target="$PLUGINS_DIR/$id"
  if [[ -e $target ]]; then
    log "Skipping $id (already installed)"
    skipped=$((skipped + 1))
    continue
  fi
  echo "Adding $id from $url"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "+ omarchy plugin add $url --yes"
    added=$((added + 1))
    continue
  fi
  if omarchy plugin add "$url" --yes; then
    added=$((added + 1))
  else
    echo "install-plugins: failed to add $id" >&2
    failed=$((failed + 1))
  fi
done < <(jq -r '.plugins[] | [.id, .url] | @tsv' "$LOCKFILE")

echo "Added $added, skipped $skipped, failed $failed"

if [[ $DRY_RUN -eq 0 && $added -gt 0 ]]; then
  run omarchy-shell shell rescanPlugins
fi

if [[ $failed -gt 0 ]]; then
  exit 1
fi
