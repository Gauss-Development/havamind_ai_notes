# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Hava Mind** — a Flutter mobile app (iOS/Android) for AI-powered audio note-taking and analysis for founders. Uses Supabase for backend (auth, database, storage, edge functions), RevenueCat for subscriptions, and Google Sign-In for OAuth.

## Common Commands

```bash
# Run (development flavor)
flutter run --flavor development -t lib/main_development.dart

# Run (production flavor)
flutter run --flavor production -t lib/main_production.dart

# Code generation (freezed models, mappers, localization)
flutter pub run build_runner build

# Generate localization strings from ARB files
flutter pub global run intl_utils:generate

# Static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/audio_notes_list_bloc_test.dart
```

## Architecture

Clean Architecture with feature-first organization. Each feature under `lib/features/` is self-contained with three layers:

- **Domain**: entities, repository interfaces, use cases (`UseCase<T, Params>` returning `Either<Failure, T>`)
- **Data**: repository implementations, remote/local data sources, DTOs with mappers
- **Presentation**: BLoC/Cubit (with Freezed states/events), pages, widgets

Shared code lives in `lib/core/` (DI, theme, error types, constants, reusable widgets).

### Key Patterns

- **State management**: `flutter_bloc` — BLoC for complex features (audio_notes, auth), Cubit for simpler ones (theme, tags, subscription)
- **Error handling**: `dartz` `Either<Failure, T>` throughout. Custom failure types: `AuthFailure`, `ServerFailure`, `PermissionFailure`, `PurchaseFailure`. Use `fold()` for branching.
- **Dependency injection**: `GetIt` service locator configured in `lib/core/di/injection.dart`. Lazy singletons for services, factories for BLoCs.
- **Immutable state**: All BLoC states/events use `@freezed` union types with `maybeWhen`/`when` for pattern matching.
- **Mappers**: Dedicated mapper classes convert between data models and domain entities.

### Audio Pipeline

Record (via `record` package) → save locally → upload to Supabase Storage (`audio-notes` bucket) → trigger Supabase Edge Function (`process-audio-note`) → AI transcription + analysis → results stored in DB.

### Features

| Feature | State Management | Key Concerns |
|---------|-----------------|--------------|
| `audio_notes` | BLoC (list, recording, detail) | Recording, upload, real-time Supabase subscriptions, processing status |
| `auth` | BLoC | Google OAuth via Supabase, profile sync, auth state stream |
| `subscription` | Cubit | RevenueCat integration, usage limits (free/basic/pro tiers) |
| `favorites` | BLoC | Toggle favorites, filtered listing |
| `tags` | Cubit | Tag management |
| `search` | Cubit | Search across notes |

## App Flavors & Entry Points

- **Development**: `lib/main_development.dart` — bundle ID `com.havamind.app.dev`
- **Production**: `lib/main_production.dart` — bundle ID `com.havamind.app`
- Bootstrap flow: load `.env` → init Supabase → register DI → run app

Environment variables are in `assets/env/` (`.env.development`, `.env.production`).

## Design System

"Soft Structuralism" aesthetic with Material 3. Key rules:
- **No-Line Rule**: No 1px borders for sections — use tonal background shifts instead
- **No-Divider Rule**: No horizontal lines in lists — use spacing or alternating backgrounds
- **Typography**: Manrope exclusively (via `google_fonts`), ExtraBold (800) for headlines
- **Corners**: Extreme corner radii (`ROUND_XL`) for main containers
- **Shadows**: Only on floating/active elements, tinted with primary Indigo color, never black
- Theme defined in `lib/core/theme/` (obsidian_theme, obsidian_colors, obsidian_ui_tokens)

## Testing

Tests use `mocktail` for mocking. Tests are in `/test/` and follow Given-When-Then structure. BLoC tests verify state transitions; repository tests verify data source orchestration.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. The
skill has multi-step workflows, checklists, and quality gates that produce better
results than an ad-hoc answer. When in doubt, invoke the skill. A false positive is
cheaper than a false negative.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke /office-hours
- Strategy, scope, "think bigger", "what should we build" → invoke /plan-ceo-review
- Architecture, "does this design make sense" → invoke /plan-eng-review
- Design system, brand, "how should this look" → invoke /design-consultation
- Design review of a plan → invoke /plan-design-review
- Developer experience of a plan → invoke /plan-devex-review
- "Review everything", full review pipeline → invoke /autoplan
- Bugs, errors, "why is this broken", "this doesn't work" → invoke /investigate
- Test the site, find bugs, "does this work" → invoke /qa (or /qa-only for report only)
- Code review, check the diff, "look at my changes" → invoke /review
- Visual polish, design audit, "this looks off" → invoke /design-review
- Developer experience audit, try onboarding → invoke /devex-review
- Ship, deploy, create a PR, "send it" → invoke /ship
- Merge + deploy + verify → invoke /land-and-deploy
- Configure deployment → invoke /setup-deploy
- Post-deploy monitoring → invoke /canary
- Update docs after shipping → invoke /document-release
- Weekly retro, "how'd we do" → invoke /retro
- Second opinion, codex review → invoke /codex
- Safety mode, careful mode, lock it down → invoke /careful or /guard
- Restrict edits to a directory → invoke /freeze or /unfreeze
- Upgrade gstack → invoke /gstack-upgrade
- Save progress, "save my work" → invoke /context-save
- Resume, restore, "where was I" → invoke /context-restore
- Security audit, OWASP, "is this secure" → invoke /cso
- Make a PDF, document, publication → invoke /make-pdf
- Launch real browser for QA → invoke /open-gstack-browser
- Import cookies for authenticated testing → invoke /setup-browser-cookies
- Performance regression, page speed, benchmarks → invoke /benchmark
- Review what gstack has learned → invoke /learn
- Tune question sensitivity → invoke /plan-tune
- Code quality dashboard → invoke /health
