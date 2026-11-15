#!/usr/bin/env bash
# Repository checks that do not need Unreal Engine.
# Run locally:  bash scripts/check-repo.sh
# Runs in CI on every push and pull request.
cd "$(dirname "$0")/.." || exit 1

errors=0
fail() { echo "  ОШИБКА: $1"; errors=$((errors + 1)); }
ok()   { echo "  ok: $1"; }

echo "1. Обязательные файлы"
for f in AGENTS.md CLAUDE.md ARCHITECTURE.md PLAN.md README.md \
         docs/GDD.md docs/DEVLOG.md docs/third-party-assets.md docs/setup/SETUP.md \
         docs/tasks/_TEMPLATE.md .claude/settings.json .gitignore .gitattributes; do
  [ -f "$f" ] || fail "нет файла $f"
done
[ $errors -eq 0 ] && ok "все на месте"

echo "2. Настройки Harness"
if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool .claude/settings.json >/dev/null 2>&1; then
    ok ".claude/settings.json — корректный JSON"
  else
    fail ".claude/settings.json — некорректный JSON"
  fi
  [ -f .mcp.json ] && { python3 -m json.tool .mcp.json >/dev/null 2>&1 || fail ".mcp.json — некорректный JSON"; }
else
  echo "  пропуск: python3 не найден, JSON не проверен"
fi
grep -q 'unreal-engine-skills-for-claude-code@claude-plugins-official' .claude/settings.json \
  && ok "плагин Epic включён" || fail "плагин Epic не включён в .claude/settings.json"
for h in $(grep -o '\.claude/hooks/[A-Za-z0-9_-]*\.sh' .claude/settings.json | sort -u); do
  [ -f "$h" ] || fail "хук $h указан в настройках, но файла нет"
done
for h in .claude/hooks/*.sh; do
  [ -f "$h" ] || continue
  head -1 "$h" | grep -q '^#!' || fail "$h: нет строки #! в начале"
  bash -n "$h" 2>/dev/null || fail "$h: синтаксическая ошибка"
done

echo "3. Роли и команды"
for f in .claude/agents/*.md .claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  head -1 "$f" | grep -q '^---$' || { fail "$f: нет заголовка (frontmatter)"; continue; }
  fm=$(awk 'NR>1 && /^---$/ {exit} NR>1 {print}' "$f")
  printf '%s\n' "$fm" | grep -q '^name:' || fail "$f: нет поля name"
  printf '%s\n' "$fm" | grep -q '^description:' || fail "$f: нет поля description"
done
for a in planner gameplay-engineer world-builder narrative-keeper qa-reviewer; do
  [ -f ".claude/agents/$a.md" ] || fail "нет роли $a"
done
grep -q '^permissionMode: plan' .claude/agents/planner.md 2>/dev/null \
  && ok "planner работает в Plan Mode" || fail "planner должен иметь permissionMode: plan"

echo "4. План"
n=$(grep -c 'Текущий этап' PLAN.md 2>/dev/null)
[ "$n" = "1" ] && ok "текущий этап указан" || fail "в PLAN.md должна быть ровно одна строка «Текущий этап» (найдено: $n)"

echo "5. Git: что не должно попадать в репозиторий"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  bad=$(git ls-files | grep -E '^(Binaries|Intermediate|Saved|DerivedDataCache)/|^Content/ThirdParty/|(^|/)\.env(\.|$)|\.(pem|key)$|^\.claude/\.state/|^\.claude/settings\.local\.json$')
  [ -z "$bad" ] && ok "кэша, сторонних наборов и секретов нет" || fail "лишние файлы в git: $(echo $bad | head -c 300)"

  assets=$(git ls-files | grep -E '\.(uasset|umap)$')
  if [ -n "$assets" ]; then
    notlfs=""
    for f in $assets; do
      git check-attr filter -- "$f" | grep -q 'filter: lfs' || notlfs="$notlfs $f"
    done
    [ -z "$notlfs" ] && ok "ассеты Unreal идут через LFS" || fail "ассеты не через LFS:$notlfs"
  else
    ok "ассетов Unreal пока нет"
  fi

  big=""
  for f in $(git ls-files); do
    [ -f "$f" ] || continue
    git check-attr filter -- "$f" | grep -q 'filter: lfs' && continue
    size=$(wc -c < "$f" | tr -d ' ')
    [ "$size" -gt 5000000 ] && big="$big $f"
  done
  [ -z "$big" ] && ok "больших файлов вне LFS нет" || fail "файлы больше 5 МБ вне LFS:$big"
else
  echo "  пропуск: это не git-репозиторий"
fi

echo
if [ $errors -eq 0 ]; then
  echo "Проверка пройдена."
  exit 0
fi
echo "Проверка не пройдена. Ошибок: $errors"
exit 1
