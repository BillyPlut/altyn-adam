#!/usr/bin/env bash
# PreToolUse(Bash): blocks commands that can destroy work or bypass the harness.
# Reads the hook JSON from stdin. Exit 2 = block, stderr is shown to the agent.
input=$(cat)

block() {
  echo "Заблокировано хуком guard-bash: $1" >&2
  echo "Не ищи обход. Если это действительно нужно, спроси владельца." >&2
  exit 2
}

has() { printf '%s' "$input" | grep -Eq -- "$1"; }

has 'git[[:space:]]+push[^"]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|\\|"|$))' \
  && block "принудительный push переписывает историю на GitHub."
has 'git[[:space:]]+push[^"]*[[:space:]](origin[[:space:]]+)?(main|master)([[:space:]]|\\|"|$)' \
  && block "прямой push в main. Работай в ветке task/... и открой pull request."
has 'git[[:space:]]+reset[[:space:]]+--hard' \
  && block "git reset --hard стирает несохранённую работу."
has 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' \
  && block "git clean -f удаляет файлы без возможности вернуть."
has 'git[[:space:]]+(filter-branch|filter-repo)|git[[:space:]]+rebase[[:space:]]+(-i|--interactive)' \
  && block "переписывание истории запрещено."
has 'git[[:space:]]+checkout[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|\\|"|$)|git[[:space:]]+restore[[:space:]]+\.([[:space:]]|\\|"|$)' \
  && block "массовый откат рабочих файлов. Откатывай конкретные файлы."
has 'git[[:space:]]+lfs[[:space:]]+uninstall' \
  && block "отключение Git LFS сломает хранение ассетов."
has 'dangerously-skip-permissions' \
  && block "запуск без подтверждений запрещён правилами проекта."
has 'rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[^"]*[[:space:]]("|\\")?(\./)?(Content|Source|Config|docs|\.claude|\.git|\.github|scripts)(/|[[:space:]]|\\|"|$)' \
  && block "рекурсивное удаление папки проекта."
has 'rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*("|\\")?(/|~|\.|\*|\.\./?)("|\\"|[[:space:]]|$)' \
  && block "рекурсивное удаление корня, домашней папки или всего подряд."

exit 0
