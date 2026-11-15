#!/usr/bin/env bash
# PreToolUse(Edit|Write): protects binary assets and asks the owner before
# changing the GDD or the harness itself.
# Exit 2 = block. JSON with permissionDecision "ask" = owner must confirm.
input=$(cat)

path=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -z "$path" ] && exit 0
# Windows paths arrive JSON-escaped (C:\\Dev\\...). Normalise to forward slashes.
path=$(printf '%s' "$path" | sed 's/\\/\//g; s#//*#/#g')

deny() {
  echo "Заблокировано хуком protect-files: $1" >&2
  exit 2
}

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

case "$path" in
  *.uasset|*.umap|*.ubulk|*.uexp|*.uptnl)
    deny "$path — бинарный ассет Unreal. Его нельзя писать как текст, только через редактор (unreal-mcp)." ;;
  */.git/*|.git/*)
    deny "прямая запись во внутренние файлы git." ;;
  */Content/ThirdParty/*|Content/ThirdParty/*)
    deny "сторонние наборы ассетов не изменяются." ;;
  */.env|.env|*/.env.*|.env.*)
    deny "файлы с секретами не создаются и не меняются агентом." ;;
esac

case "$path" in
  */docs/GDD.md|docs/GDD.md)
    ask "GDD — источник истины, его меняет только владелец. Подтвердите правку." ;;
  */.claude/settings.json|.claude/settings.json|*/.claude/hooks/*|.claude/hooks/*)
    ask "Изменение защитных настроек Harness. Подтвердите правку." ;;
  */.github/workflows/*|.github/workflows/*)
    ask "Изменение CI. Подтвердите правку." ;;
esac

exit 0
