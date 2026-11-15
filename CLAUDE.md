# CLAUDE.md

Общие правила проекта — в `AGENTS.md`. Они обязательны.

@AGENTS.md

## Только для Claude Code

- Подключён плагин Epic `unreal-engine-skills-for-claude-code` (см. `.claude/settings.json`). Для любой работы с редактором используй его навык `unreal-mcp`. Сервер MCP работает, только пока открыт Unreal Editor.
- Команды проекта: `/next-task`, `/ue-checkpoint`, `/done`, `/gdd-check` (лежат в `.claude/skills/`).
- Роли: `planner`, `gameplay-engineer`, `world-builder`, `narrative-keeper`, `qa-reviewer` (лежат в `.claude/agents/`). Делегируй по ролям, а не делай всё в основной сессии.
- Планирование всегда идёт в Plan Mode: либо через агента `planner`, либо переключением режима (Shift+Tab).
- Хуки в `.claude/hooks/` защищают проект. Их описание — в `ARCHITECTURE.md`, раздел «Harness».
- Если `/mcp` не показывает `unreal-mcp`, открой `docs/setup/SETUP.md`, раздел «Если что-то не работает».
