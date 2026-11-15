#!/usr/bin/env bash
# PreToolUse(mcp__unreal-mcp.*): the first editor call in a session requires a
# clean working tree, so anything the agent does in the editor can be undone.
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

session=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | tr -cd 'A-Za-z0-9_-')
[ -z "$session" ] && session="unknown"

state_dir=".claude/.state"
marker="$state_dir/ue-checkpoint-$session"
[ -f "$marker" ] && exit 0

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "Заблокировано хуком ue-checkpoint-guard: в рабочем дереве есть несохранённые изменения." >&2
  echo "Перед первой работой в редакторе за сессию нужен чекпойнт. Выполни /ue-checkpoint и повтори вызов." >&2
  exit 2
fi

mkdir -p "$state_dir" 2>/dev/null && : > "$marker"
exit 0
