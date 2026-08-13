#!/usr/bin/env bash
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
client=${1:-cursor}

install_cursor() {
  local install_root install_path current_target staging_path backup_path installed_name
  install_root="${CURSOR_PLUGIN_HOME:-$HOME/.cursor/plugins/local}"
  install_path="$install_root/project-feed"

  mkdir -p "$install_root"

  staging_path=$(mktemp -d "$install_root/.project-feed.XXXXXX")
  cp -R \
    "$plugin_root/.cursor-plugin" \
    "$plugin_root/assets" \
    "$plugin_root/skills" \
    "$staging_path/"
  cp \
    "$plugin_root/LICENSE" \
    "$plugin_root/README.md" \
    "$plugin_root/SECURITY.md" \
    "$plugin_root/mcp.json" \
    "$staging_path/"

  if [[ -L "$install_path" ]]; then
    current_target=$(readlink "$install_path")
    if [[ "$current_target" != "$plugin_root" ]]; then
      printf 'Refusing to replace symlink at %s\n' "$install_path" >&2
      rm -rf "$staging_path"
      exit 1
    fi
    unlink "$install_path"
  elif [[ -d "$install_path" ]]; then
    installed_name=$(node -e 'try { console.log(require(process.argv[1]).name) } catch {}' "$install_path/.cursor-plugin/plugin.json")
    if [[ "$installed_name" != "project-feed" ]]; then
      printf 'Refusing to replace directory at %s\n' "$install_path" >&2
      rm -rf "$staging_path"
      exit 1
    fi
    backup_path=$(mktemp -d "$install_root/.project-feed.previous.XXXXXX")
    rmdir "$backup_path"
    mv "$install_path" "$backup_path"
  elif [[ -e "$install_path" ]]; then
    printf 'Refusing to replace path at %s\n' "$install_path" >&2
    rm -rf "$staging_path"
    exit 1
  fi

  if ! mv "$staging_path" "$install_path"; then
    if [[ -n "${backup_path:-}" ]]; then
      mv "$backup_path" "$install_path"
    fi
    exit 1
  fi

  if [[ -n "${backup_path:-}" ]]; then
    rm -rf "$backup_path"
  fi

  printf 'Installed Project Feed in Cursor at %s\n' "$install_path"
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
