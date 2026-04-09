# AGENTS.md

## Where to work

**All active development is in `Mobile/`. Do not read, search, or modify `PC/`.**

`PC/` is frozen (Angular 19 + planned Spring Boot). `Mobile/` (Flutter + Node.js mock server) is the only active subproject.

## Quick verification

```bash
# Flutter — run from Mobile/mobile_app/
cd Mobile/mobile_app
flutter analyze
flutter test

# Mock Server — run from Mobile/backend/
cd Mobile/backend && node server.js  # port 3001

# One-shot dev environment
cd Mobile && ./dev.sh start [mock|live]
```

## Detailed guidance

See `Mobile/AGENTS.md` for architecture, coding patterns, testing conventions, and style rules.

## Key constraints

- No comments in code unless user explicitly requests them
- Chinese UI text, English variable/class names
- `flutter_riverpod` exclusively — no `setState` or `ChangeNotifier`
- Every interactive UI element must have a `Key('descriptive-id')` for testing
- Theme tokens (`AppColors`/`AppSpacing`/`AppTypography`) instead of hardcoded values

## Git

- Default branch: `master`
- Remote: `https://github.com/aime4eve/smart-livestock`
- `gh` CLI is authenticated as `aime4eve`
- No CI/CD configured
