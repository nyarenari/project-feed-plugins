#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
client=${1:-cursor}

install_cursor() {
  local install_root install_path current_target
  install_root="${CURSOR_PLUGIN_HOME:-$HOME/.cursor/plugins/local}"
  install_path="$install_root/project-feed"

  mkdir -p "$install_root"

  if [[ -L "$install_path" ]]; then
    current_target=$(readlink "$install_path")
    if [[ "$current_target" == "$plugin_root" ]]; then
      printf 'Project Feed is already linked in Cursor at %s\n' "$install_path"
      return
    fi
    printf 'Refusing to replace symlink at %s\n' "$install_path" >&2
    exit 1
  fi

  if [[ -e "$install_path" ]]; then
    printf 'Refusing to replace existing path at %s\n' "$install_path" >&2
    exit 1
  fi

  ln -s "$plugin_root" "$install_path"
  printf 'Linked Project Feed in Cursor at %s\n' "$install_path"
  printf 'Restart Cursor or run Developer: Reload Window.\n'
}

install_codex() {
  command -v codex >/dev/null || {
    printf 'Codex is not installed.\n' >&2
    exit 1
  }
  if ! codex plugin marketplace list | rg -q "^project-feed[[:space:]]"; then
    codex plugin marketplace add "$plugin_root"
  fi
  codex plugin add project-feed@project-feed
  printf 'Installed Project Feed in Codex. Start Codex with PROJECT_FEED_API_KEY set.\n'
}

install_claude() {
  command -v claude >/dev/null || {
    printf 'Claude Code is not installed.\n' >&2
    exit 1
  }
  claude plugin marketplace add "$plugin_root"
  claude plugin install project-feed@project-feed
  printf 'Installed Project Feed in Claude Code. Run /plugin configure project-feed@project-feed to add the API key.\n'
}

install_gemini() {
  command -v gemini >/dev/null || {
    printf 'Gemini CLI is not installed.\n' >&2
    exit 1
  }
  gemini extensions link "$plugin_root"
  printf 'Linked Project Feed in Gemini CLI. Configure the extension setting when prompted.\n'
}

case "$client" in
  cursor) install_cursor ;;
  codex) install_codex ;;
  claude) install_claude ;;
  gemini) install_gemini ;;
  *)
    printf 'Usage: %s {cursor|codex|claude|gemini}\n' "$0" >&2
    exit 2
    ;;
esac
