#!/usr/bin/env bash
# SessionStart: gives the agent the current milestone, next tasks and git state.
# Output goes to the agent's context. Never fails the session.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

echo "=== Altyn Adam: состояние проекта ==="

if [ -f PLAN.md ]; then
  stage=$(grep -m1 'Текущий этап' PLAN.md | sed 's/\*//g')
  [ -n "$stage" ] && echo "$stage"
  echo "Ближайшие невыполненные задачи:"
  grep -m3 -E '^- \[ \] \*\*M[0-9]+-[0-9]+\*\*' PLAN.md | sed 's/\*\*//g; s/^- \[ \] /  - /'
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "Git: ветка ${branch}, несохранённых изменений: ${changes}"
fi

if ls ./*.uproject >/dev/null 2>&1; then
  [ -f .mcp.json ] || echo "Внимание: .mcp.json не найден. См. docs/setup/SETUP.md, шаг 6."
else
  echo "Проект Unreal ещё не добавлен в репозиторий (этап M0)."
fi

echo "Правила: AGENTS.md. Работа начинается с /next-task, планирование только в Plan Mode."
exit 0
