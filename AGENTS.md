# AGENTS.md

## Where to work

**All active development is in `Mobile/`. Do not read, search, or modify `PC/`.**

`PC/` is frozen (Angular 19 + planned Spring Boot). `Mobile/` (Flutter app + Vue 3 developer portal) is the only active subproject.

## Project layout

```
smart-livestock/
├── Mobile/                  # ← active development
│   ├── mobile_app/          # Flutter app (Dart)
│   ├── developer-portal/    # Vue 3 API consumer portal
│   └── playwright.config.js # E2E config
├── smart-livestock-server/  # Spring Boot 3 backend (Java 17)
├── PC/                      # FROZEN — do not touch
├── tooling/                 # MBTiles / tileserver scripts
└── docs/                    # Plans, guides, API contracts
```

## Quick verification

```bash
# Flutter — run from Mobile/mobile_app/
cd Mobile/mobile_app
flutter pub get
flutter analyze
flutter test
flutter test test/features/fence/fence_hit_detection_test.dart   # single file
flutter test --name="owner"                                       # by name pattern

# Developer Portal — run from Mobile/developer-portal/
cd Mobile/developer-portal
npm install
npm run build
npm test

# Spring Boot backend — run from smart-livestock-server/
cd smart-livestock-server
./gradlew test
./gradlew bootRun                # starts on port 8080

# Docker Compose (full stack)
cd smart-livestock-server
docker compose up                # nginx :18080 → app :8080
```

## Detailed guidance

See `Mobile/AGENTS.md` for architecture, coding patterns, testing conventions, and style rules.

## Key constraints

- No comments in code unless user explicitly requests them
- Chinese UI text, English variable/class names
- `flutter_riverpod` exclusively — no `setState` or `ChangeNotifier`
- Every interactive UI element must have a `Key('descriptive-id')` for testing
- Theme tokens (`AppColors`/`AppSpacing`/`AppTypography`) instead of hardcoded values
- No secrets or API keys in code

## Web caveat

Web targets `http://127.0.0.1:18080/api/v1` (avoids IPv6 localhost). If connection fails:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:18080/api/v1
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
