# AGENTS.md

## Where to work

**All active development is in `Mobile/`. Do not read, search, or modify `PC/`.**

`PC/` is frozen (Angular 19 + planned Spring Boot). `Mobile/` (Flutter + Node.js mock server) is the only active subproject.

## Quick verification

```bash
# Flutter — run from Mobile/mobile_app/
cd Mobile/mobile_app
flutter pub get
flutter analyze
flutter test
flutter test test/role_visibility_test.dart          # single test file
flutter test --name="owner"                           # by name pattern

# Mock Server — run from Mobile/backend/
cd Mobile/backend && npm test                         # geo + fenceStore tests
cd Mobile/backend && node server.js                   # port 3001

# One-shot dev environment
cd Mobile && ./dev.sh start [mock|live]
cd Mobile && ./dev.sh diagnose                        # logs + error grep for white-screen/WASM issues
```

## Detailed guidance

See `Mobile/AGENTS.md` for architecture, coding patterns, testing conventions, and style rules.

## Key constraints

- No comments in code unless user explicitly requests them
- Chinese UI text, English variable/class names
- `flutter_riverpod` exclusively — no `setState` or `ChangeNotifier`
- Every interactive UI element must have a `Key('descriptive-id')` for testing
- Theme tokens (`AppColors`/`AppSpacing`/`AppTypography`) instead of hardcoded values
- No real backend calls — all data is local mock or Node.js mock server (port 3001)
- No secrets or API keys in code

## Web caveat

Live mode on web targets `http://127.0.0.1:3001/api` (avoids IPv6 localhost). If connection fails:
```bash
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

## Issue-driven workflow

1. Claim: `gh issue edit <N> --add-assignee aime4eve`
2. Find plan: search `docs/superpowers/plans/*.md` for `#N`
3. Implement per plan, run `flutter analyze` + `flutter test`
4. PR body: `Closes #N`
5. Update plan's completion record table

## Git

- Default branch: `master`
- Remote: `https://github.com/aime4eve/smart-livestock`
- `gh` CLI authenticated as `aime4eve`
- No CI/CD configured
