#!/usr/bin/env bash
# Install the discord-components-v2 skill into an agent's skill directory.
# Works on macOS, Linux, WSL and Git Bash. No dependencies beyond coreutils.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/SKILL.md"

SKILL_NAME="discord-components-v2"
if [ -f "$SKILL_FILE" ]; then
  parsed="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_FILE" | head -n 1 | tr -d '\r"')"
  if [ -n "$parsed" ]; then
    SKILL_NAME="$parsed"
  fi
fi

if [ -t 1 ]; then
  GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; RESET=''
fi

# target -> install-relative directory
target_rel() {
  case "$1" in
    agents)      echo ".agents/skills" ;;
    claude-code) echo ".claude/skills" ;;
    cursor)      echo ".cursor/skills" ;;
    codex)       echo ".codex/skills" ;;
    *)           return 1 ;;
  esac
}

usage() {
  cat <<'EOF'
Install the discord-components-v2 skill for AI coding agents.

Usage:
  ./install.sh [options]

Options:
  -t, --target NAME   Agent to install for: agents (default), claude-code,
                      cursor, codex
  -g, --global        Install into your home directory instead of the
                      current project
  -d, --dir PATH      Install into an explicit directory (overrides --target)
  -f, --force         Overwrite an existing installation without asking
  -u, --uninstall     Remove the installed copy
  -n, --dry-run       Print what would happen, change nothing
  -l, --list-targets  Show supported targets and their directories
  -h, --help          Show this help

Examples:
  ./install.sh                          # .agents/skills/discord-components-v2
  ./install.sh -t claude-code -g        # ~/.claude/skills/discord-components-v2
  ./install.sh -t cursor -g             # ~/.cursor/skills/discord-components-v2
  ./install.sh -d /tmp/skills           # /tmp/skills/discord-components-v2
  ./install.sh -u -t claude-code        # remove the project-level copy

Installing via the skills CLI instead:
  npx skills add Dqrshan/discord-components-v2-skill
EOF
}

list_targets() {
  for t in agents claude-code cursor codex; do
    printf '  %-12s %s\n' "$t" "$(target_rel "$t")"
  done
  printf '\nPaths are relative to the project root, or to $HOME with --global.\n'
}

TARGET="agents"
GLOBAL=0
CUSTOM_DIR=""
FORCE=0
UNINSTALL=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -t|--target)
      [ $# -ge 2 ] || { echo "error: $1 requires a value" >&2; exit 2; }
      TARGET="$2"; shift 2 ;;
    -g|--global)      GLOBAL=1; shift ;;
    -d|--dir)
      [ $# -ge 2 ] || { echo "error: $1 requires a value" >&2; exit 2; }
      CUSTOM_DIR="$2"; shift 2 ;;
    -f|--force)       FORCE=1; shift ;;
    -u|--uninstall)   UNINSTALL=1; shift ;;
    -n|--dry-run)     DRY_RUN=1; shift ;;
    -l|--list-targets) list_targets; exit 0 ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "error: unknown option '$1' (try --help)" >&2; exit 2 ;;
  esac
done

if [ "$TARGET" = "claude" ]; then
  TARGET="claude-code"
fi

if [ -n "$CUSTOM_DIR" ]; then
  case "$CUSTOM_DIR" in
    /*) BASE="$CUSTOM_DIR" ;;
    *)  BASE="$(pwd)/$CUSTOM_DIR" ;;
  esac
else
  REL="$(target_rel "$TARGET")" || {
    echo "error: unsupported target '$TARGET'" >&2
    list_targets >&2
    exit 2
  }
  if [ "$GLOBAL" -eq 1 ]; then BASE="$HOME/$REL"; else BASE="$(pwd)/$REL"; fi
fi

DEST="$BASE/$SKILL_NAME"

say()  { printf '%s\n' "$*"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %s\n" "$*"; }
die()  { printf "${RED}error:${RESET} %s\n" "$*" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  would run: %s\n' "$*"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------- uninstall
if [ "$UNINSTALL" -eq 1 ]; then
  if [ ! -d "$DEST" ]; then
    warn "nothing installed at $DEST"
    exit 0
  fi
  run rm -rf "$DEST"
  ok "removed $DEST"
  exit 0
fi

# ------------------------------------------------------------------ install
[ -f "$SKILL_FILE" ] || die "SKILL.md not found next to install.sh ($SCRIPT_DIR)"

if [ -e "$DEST" ] && [ "$FORCE" -eq 0 ]; then
  if [ -t 0 ]; then
    printf 'A copy already exists at %s\nOverwrite? [y/N] ' "$DEST"
    read -r answer
    case "$answer" in
      y|Y|yes|YES) ;;
      *) say "Aborted."; exit 1 ;;
    esac
  else
    die "$DEST already exists (use --force to overwrite)"
  fi
fi

say ""
say "Installing ${SKILL_NAME} → ${DEST}"
say ""

# SKILL.md is self-contained; nothing else from this repo is part of the skill.
run mkdir -p "$DEST"
run cp "$SKILL_FILE" "$DEST/SKILL.md"

if [ "$DRY_RUN" -eq 0 ]; then
  ok "Installed to $DEST"
  say ""
  say "Files:"
  find "$DEST" -type f | sed "s|^$DEST/|  |" | sort
  say ""
  say "Try asking your agent: \"build a Discord announcement message with Components V2\""
  say "Requires discord.js >= 14.19 in your bot project."
  say ""
fi
