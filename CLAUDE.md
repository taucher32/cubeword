# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Cubeword — a Flutter word-puzzle game (code comments are in Turkish throughout; in-game UI/copy is
bilingual, see Localization below). Players rotate cubes to reveal letters and build a target word on a
2×6 grid.

## Commands

```bash
flutter pub get              # install dependencies
flutter run                  # run the app
flutter test                 # run all tests
flutter test test/game_provider_test.dart   # run a single test file
flutter test --plain-name "reveals target word"  # run a single test by name
flutter analyze               # static analysis (flutter_lints via analysis_options.yaml)
```

There is no CI config in this repo; `flutter analyze` and `flutter test` are the checks to run before
considering a change done.

## Architecture

Standard Provider (ChangeNotifier) state management, no routing package — `Navigator.push` between two
screens. `GameProvider` is *not* app-global: `GameScreen` creates its own instance (scoped with a local
`ChangeNotifierProvider` + `Builder`, see below) each time it's pushed, parameterized by the language
chosen on the start screen.

- **`lib/providers/game_provider.dart`** — the entire game engine and single source of truth. Everything
  about game state, scoring, round progression, and UI copy lives here; widgets are dumb renderers driven
  by `Consumer<GameProvider>`. Key concepts:
  - **Grid**: `List<List<Cube?>>` sized `2 rows × 6 cols`. Row 0 (`spawnRow`) holds cubes players rotate;
    row 1 (`wordRow`) holds cubes dropped in to form the submitted word. A column can only be occupied in
    one row at a time.
  - **Rotation-to-target model**: each cube's faces are built so the target letter for that column sits at
    a precomputed offset (`_targetRotationCounts[col]`, randomized 1–4). Rotating consumes one of a
    limited `rotationLimit` per cube (harder rounds grant fewer rotations, see `_rotationsPerCube`).
  - **Difficulty/word pools**: per-language pools (`_easyWordsTr`/`_mediumWordsTr`/`_hardWordsTr` and the
    `...En` equivalents) are chosen by `_roundNumber` (rounds 1–3, 4–7, 8+) and by `language`. Every word in
    a TR pool must also exist in `assets/words_tr.txt`, and every EN pool word in `assets/words_en.txt` (the
    validation dictionaries), or submissions will fail dictionary checks.
  - **Special cubes** (`CubeType.joker`, `CubeType.hint`) are injected via `_pickSpecialCubeCols()`:
    a joker appears once combo count reaches 3 (spawns pre-set to the correct letter); a hint appears
    every 3rd round (first tap jumps straight to the target letter for free).
  - **`submitWord()`** has three outcomes: dictionary-invalid (resets combo), matches target word (reveals
    target, ends round scoring, `nextRound()` becomes available), or valid-but-not-target (scores points,
    respawns fresh cubes in the word-row columns so play continues within the same round).
  - Combo count drives a score multiplier (`comboMultiplier`: ×1 / ×2 at 2+ / ×3 at 4+) and resets to 0 on
    an invalid submission.
  - High score is persisted via `shared_preferences` (`_loadHighScore`/`_saveHighScoreIfNeeded`); storage
    errors (e.g. no Flutter binding in plain `test()` unit tests) are swallowed silently by design.

- **Localization** — no `intl`/ARB setup; this is a two-language (`GameLanguage.tr`/`.en`) game with all
  copy as literal string pairs. `GameProvider` takes a `language` constructor param and exposes both
  gameplay-affecting state (word pools, `WordDictionary.isValid(word, language)`) and *all* UI-facing
  label getters (`scoreLabel`, `roundLabel`, `statsDialogTitle`, `submitWordLabel`, etc.) computed via a
  private `_t(tr, en)` helper. `game_screen.dart` never hardcodes user-facing strings — every label comes
  from a `provider.*Label`/`*Tooltip` getter, keeping translation centralized in the provider. When adding
  new user-facing copy, add a `_t(...)`-based getter to `GameProvider` rather than branching in the widget.

- **`lib/data/word_dictionary.dart`** — static dictionary loader/validator, one `Set<String>` per language.
  Loads and normalizes both `assets/words_tr.txt` and `assets/words_en.txt` at startup
  (`WordDictionary.init()`, called from `main()`); falls back to small built-in word sets per language if
  either asset fails to load. Normalization uppercases and strips Turkish-specific characters
  (İ/Ş/Ğ/Ü/Ö/Ç) to their ASCII equivalents (harmless no-op for English) — keep any new word lists
  consistent with this normalization or lookups will silently fail. `isValid(word, language)` defaults to
  `GameLanguage.tr`.

- **`lib/models/cube.dart`** — plain data model: a cube's `faces` (letters), current `topFaceIndex`,
  remaining `rotationLimit`, and `CubeType`. No game logic beyond `rotate()`.

- **`lib/models/game_language.dart`** — `enum GameLanguage { tr, en }`, shared by `GameProvider` and
  `WordDictionary` to avoid a circular import between them.

- **`lib/screens/`** — `start_screen.dart` (animated title/intro; two buttons — "Başla" pushes
  `GameScreen(language: GameLanguage.tr)`, "Start" pushes `GameScreen(language: GameLanguage.en)`) and
  `game_screen.dart` (the entire board UI: spawn row, word row, target mask, stats dialog, rewarded-ad
  button). `GameScreen.build()` wraps its subtree in a local `ChangeNotifierProvider<GameProvider>` (via a
  `Builder` so `context.read<GameProvider>()` resolves below the new provider) — each push gets a fresh
  game in the chosen language. All game actions go through `context.read<GameProvider>()` /
  `Consumer<GameProvider>`.

- **`lib/services/ad_service.dart`** — wraps `google_mobile_ads` rewarded ads. Watching an ad grants
  `+3` bonus rotations via `GameProvider.addBonusRotations()`. Uses Google's official test ad unit ID in
  debug/profile builds (`kReleaseMode` check) and the real, hardcoded production ID only in release builds.

## Notes for changes

- Widget tests rely on specific `Key`s (`score-text`, `word-row-text`, `status-text`, `submit-word`,
  `clear-word-row`, `cell-<row>-<col>`, `start-game`, `start-game-en`). Preserve these keys when touching
  `game_screen.dart` or `start_screen.dart`.
- If adding words to a difficulty pool in `game_provider.dart` (`_easyWordsTr`/`_mediumWordsTr`/
  `_hardWordsTr` or the `...En` equivalents), they must also be present in the matching dictionary asset
  (`assets/words_tr.txt` / `assets/words_en.txt`), otherwise the target word itself will fail dictionary
  validation on submit.
- `test/game_provider_test.dart` and `test/widget_test.dart` currently have a handful of pre-existing
  failing/flaky tests unrelated to language support (stale assumptions about a fixed 6-letter target word,
  a stale `"Seviye:"` label expectation, and a plain `test()` that never calls `WordDictionary.init()` so
  it only sees the small built-in fallback set). Don't assume a red run means your change broke something —
  check whether the same test fails on a clean run first.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (taucher32/cubeword), using the `gh` CLI. External PRs are not treated as a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix) — no overrides. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
