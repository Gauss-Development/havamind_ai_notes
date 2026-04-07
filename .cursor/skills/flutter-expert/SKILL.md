---
name: flutter-expert
description: Guides Flutter/Dart development with Clean Architecture, feature-first modules, flutter_bloc (Bloc/Cubit), Freezed, GetIt, Dartz, repositories, and testing. Use when building or refactoring Flutter apps, state management, DI, API layers, error handling, performance, or unit tests.
---

# Flutter expert (Clean Architecture)

Default stance: production-quality Flutter with **Clean Architecture**, **feature-first** layout, and **flutter_bloc**. Prefer simple, maintainable solutions; extend only when the domain justifies it.

For project-specific conventions already in-repo, align with [.cursor/rules/flutter-rule.mdc](../../rules/flutter-rule.mdc).

## Architecture

- Organize by **feature** (`data` / `domain` / `presentation`); shared code lives in `core/`.
- Enforce **Presentation → Domain ← Data**; domain stays framework-free (no Flutter imports, no DTOs as entities).
- **Presentation**: UI, blocs/cubits, thin mapping to view models; no direct data sources or raw API calls.
- **Domain**: entities, repository contracts, use cases; business rules live here.
- **Data**: models/DTOs, remote/local sources, repository implementations; map exceptions to `Failure`, models to entities.

## State management (flutter_bloc)

- Use **Bloc** for event-heavy flows; **Cubit** for simpler state.
- Prefer **Freezed** for immutable states and unions; explicit loading / success / empty / error where useful.
- Minimize rebuilds: `BlocSelector`, `buildWhen`, small widgets, `const` where possible.
- Side effects: **BlocListener** (navigation, snackbars, one-shot actions), not inside `build`.

## Backend and data

- **Repository** is the app boundary; **data sources** are remote vs local only.
- JSON/models stay in data; **map to domain entities** before presentation.
- Add caching/offline only when requirements demand it; keep policy in data/repository.

## Error handling (Dartz)

- Prefer **`Either<Failure, T>`** across domain boundaries; avoid exceptions as control flow outside data.
- Define a small **Failure** hierarchy; map low-level errors in data layer.
- UI sees **failures or user-safe messages**, not raw stack traces or HTTP details.

## Dependency injection (GetIt)

- Register **per feature** where it keeps modules clear; singletons for shared services, factories for blocs/cubits.
- Blocs/cubits receive use cases or repositories—not concrete HTTP clients or `BuildContext`.

## Performance

- Favor **const** constructors and shallow widget trees; avoid unnecessary `setState`/rebuilds.
- Lists: **builder** patterns, pagination/lazy loading for large sets.
- Move heavy work off the UI isolate (`compute` or isolates when justified).

## Code quality

- Null-safe, strongly typed, **SOLID**-friendly; small functions/classes; meaningful names.
- Avoid god widgets, feature coupling, and leaking infrastructure types into presentation.

## Testing

- Unit-test **use cases**, **repositories**, and **bloc/cubit** logic; use **mocktail** or mockito.
- Cover **success and failure** paths; structure tests as **Given / When / Then**.

## Problem solving

- Decompose work into small steps; prefer the **simplest** design that meets requirements.
- Call out **trade-offs** when choosing between speed and maintainability; bias toward **maintainability**.
