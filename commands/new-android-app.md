# /new-android-app — Scaffold a New Android Project from Blueprint

You are scaffolding a new Android project based on an existing blueprint document. This command bridges the gap between the blueprint (requirements) and a working project skeleton.

## Input

$ARGUMENTS should contain either:
- A path to a blueprint `.md` file, OR
- An app name (will search for `[appname]_blueprint_*.md` in the current directory)

If no blueprint is found, suggest running `/app-interview` followed by `/blueprint` first.

## Scaffolding Steps

Execute these steps in order. Use TDD methodology — test files are created alongside production files.

### Step 1: Read and Validate Blueprint

Read the blueprint file completely. Verify it contains:
- Tech stack section with version numbers
- Module structure definition
- Database schema (if applicable)
- Feature specifications with acceptance criteria
- Navigation architecture

If any critical section is missing, report what's missing and ask whether to proceed or fix the blueprint first.

### Step 2: Create Project Structure

```
[app-name]/
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/[package]/
│       │   │   ├── App.kt                    # Application class with Hilt
│       │   │   ├── MainActivity.kt            # Single activity, Compose host
│       │   │   ├── navigation/
│       │   │   │   ├── NavGraph.kt
│       │   │   │   └── Screen.kt              # Sealed class for routes
│       │   │   └── ui/theme/
│       │   │       ├── Color.kt
│       │   │       ├── Theme.kt
│       │   │       └── Type.kt
│       │   └── res/
│       │       └── values/
│       │           ├── strings.xml
│       │           └── themes.xml
│       ├── test/                              # Unit tests
│       └── androidTest/                       # Instrumented tests
├── core/
│   ├── data/
│   │   ├── build.gradle.kts
│   │   └── src/main/java/[package]/core/data/
│   │       ├── local/                         # Room database, DAOs
│   │       ├── remote/                        # Retrofit services
│   │       └── repository/                    # Repository implementations
│   ├── domain/
│   │   ├── build.gradle.kts
│   │   └── src/main/java/[package]/core/domain/
│   │       ├── model/                         # Domain models
│   │       ├── repository/                    # Repository interfaces
│   │       └── usecase/                       # UseCase classes
│   └── common/
│       ├── build.gradle.kts
│       └── src/main/java/[package]/core/common/
│           ├── Result.kt                      # Result wrapper
│           ├── di/                            # Common Hilt modules
│           └── util/                          # Extension functions
├── feature/
│   └── [per feature from blueprint]/
│       ├── build.gradle.kts
│       └── src/
│           ├── main/java/[package]/feature/[name]/
│           │   ├── [Name]Screen.kt
│           │   ├── [Name]ViewModel.kt
│           │   ├── [Name]UiState.kt
│           │   └── di/
│           │       └── [Name]Module.kt
│           └── test/java/[package]/feature/[name]/
│               └── [Name]ViewModelTest.kt
├── build.gradle.kts                           # Root build file
├── settings.gradle.kts                        # Module includes
├── gradle.properties
├── gradle/
│   └── libs.versions.toml                     # Version catalog
└── .claude/
    └── CLAUDE.md                              # Project conventions for Claude Code
```

### Step 3: Generate Version Catalog

Create `gradle/libs.versions.toml` with ALL dependencies from the blueprint. Use the exact versions specified. Structure:

```toml
[versions]
kotlin = "2.3.10"
agp = "9.0.1"
hilt = "2.55"
room = "2.7.1"
composeBom = "2026.03.00"
# ... all versions from blueprint

[libraries]
# ... all library declarations

[bundles]
compose = ["compose-ui", "compose-ui-graphics", "compose-material3", ...]
testing = ["junit5", "mockk", "turbine", ...]

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
```

### Step 4: Generate CLAUDE.md

Create `.claude/CLAUDE.md` with project conventions:

```markdown
# [App Name]

## Build & Run
- `./gradlew assembleDebug` — build debug APK
- `./gradlew test` — run all unit tests
- `./gradlew connectedAndroidTest` — run instrumented tests
- `./gradlew ktlintCheck` — check code style
- `./gradlew ktlintFormat` — auto-fix code style

## Architecture
- MVVM + Clean Architecture (data → domain ← presentation)
- Unidirectional Data Flow: Event → ViewModel → UiState → UI
- Repository pattern: interface in domain, implementation in data

## Conventions
- Kotlin: follow official Kotlin coding conventions
- Compose: stateless composables, state hoisting, preview annotations
- Naming: PascalCase for composables, camelCase for functions, SCREAMING_SNAKE for constants
- Tests: Given-When-Then naming pattern
- Commits: conventional commits (feat/fix/chore/test/refactor)

## Dependencies
All versions managed in gradle/libs.versions.toml — never hardcode versions in build.gradle.kts

## TDD Workflow
1. Write failing test first
2. Implement minimal code to pass
3. Refactor while keeping tests green
```

### Step 5: Summary Report

After scaffolding, present a summary:
- Total files created
- Module structure overview
- Suggested next steps (which feature to implement first per the roadmap)
- Reminder to run `./gradlew build` to verify the skeleton compiles

## Rules

- Generate ALL files with real, compilable Kotlin code for the skeleton (Application class, MainActivity, Theme, NavGraph, build files).
- Feature modules get only the structure + ViewModel test stubs — the actual implementation comes later via TDD.
- Never skip the CLAUDE.md — it's essential for subsequent Claude Code sessions.
- Package name convention: `nl.[username].[appname]` unless specified otherwise.
