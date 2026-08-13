#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
install_root="${CURSOR_PLUGIN_HOME:-$HOME/.cursor/plugins/local}"
install_path="$install_root/project-feed"

mkdir -p "$install_root"

if [[ -L "$install_path" ]]; then
  current_target=$(readlink "$install_path")
  if [[ "$current_target" == "$plugin_root" ]]; then
    printf 'Project Feed is already linked at %s\n' "$install_path"
    exit 0
  fi
  printf 'Refusing to replace symlink at %s\n' "$install_path" >&2
  exit 1
fi

if [[ -e "$install_path" ]]; then
  printf 'Refusing to replace existing path at %s\n' "$install_path" >&2
  exit 1
fi

ln -s "$plugin_root" "$install_path"
printf 'Linked Project Feed at %s\n' "$install_path"
printf 'Restart Cursor or run Developer: Reload Window.\n'
