# /blueprint — Generate Android App Blueprint

You are generating a comprehensive Android app blueprint document following the established blueprint methodology. This blueprint is a **requirements-only document** — it contains NO implementation code, only specifications that a Claude Code agent can execute against.

## Input

$ARGUMENTS should contain the app name and optionally a brief description or a path to a requirements summary produced by `/app-interview`.

If a requirements summary file is referenced, read it first. If no requirements are provided, ask the user for the core concept before proceeding.

## Blueprint Structure

Generate a complete `.md` file with ALL of the following sections. Every section must be substantive — no placeholders or "TBD" entries.

### Required Sections (in order)

```markdown
# [App Name] Blueprint v1

## 1. Project Overview
### 1.1 Vision & Purpose
### 1.2 Target Audience
### 1.3 Value Proposition
### 1.4 Success Metrics (KPIs)

## 2. Technical Foundation
### 2.1 Tech Stack
- Language: Kotlin 2.3.10
- Build: AGP 9.0.1, Gradle 8.x (Kotlin DSL)
- DI: Hilt 2.55
- Database: Room 2.7.1
- UI: Jetpack Compose (BOM 2026.x)
- Navigation: Compose Navigation (type-safe)
- Async: Kotlin Coroutines + Flow
- Networking: Retrofit 2.x + OkHttp 4.x + Kotlin Serialization
- Image loading: Coil 3.x (Compose)
- Testing: JUnit 5, Turbine, MockK, Compose UI Testing

### 2.2 Architecture Pattern
- MVVM + Clean Architecture (3 layers: data, domain, presentation)
- Unidirectional Data Flow (UDF)
- Repository pattern for data access
- UseCase classes for business logic

### 2.3 Module Structure
[Define Gradle modules: app, core, feature modules]

### 2.4 Minimum SDK & Target SDK
- minSdk: 26 (Android 8.0)
- targetSdk: 36
- compileSdk: 36

## 3. Data Architecture
### 3.1 Local Database Schema
[Room entities, DAOs, relationships, migrations strategy]

### 3.2 Remote API Integration
[Endpoints, request/response models, error handling]

### 3.3 Data Sync Strategy
[Offline-first approach, conflict resolution, sync triggers]

### 3.4 Caching Strategy
[Cache invalidation, TTL, storage limits]

## 4. Feature Specifications
### 4.x [Feature Name]
#### User Story
#### Acceptance Criteria
#### Screen Specifications
#### State Management (UiState sealed interface)
#### Error Handling
#### Edge Cases

## 5. Navigation Architecture
### 5.1 Navigation Graph
[Screens, routes, deep links]

### 5.2 Navigation Patterns
[Bottom navigation, drawer, nested graphs]

### 5.3 Back Stack Behavior
[Pop behavior, save state, restore]

## 6. UI/UX Specifications
### 6.1 Design System
[Color palette, typography scale, spacing, elevation]

### 6.2 Theme Configuration
[Material 3 dynamic color, dark/light mode]

### 6.3 Component Library
[Custom reusable composables needed]

### 6.4 Accessibility
[Content descriptions, touch targets, TalkBack support]

## 7. Security & Privacy
### 7.1 Authentication
[Auth flow, token management, biometric]

### 7.2 Data Protection
[Encryption at rest, in transit, key management]

### 7.3 Privacy Compliance
[AVG/GDPR, data minimization, consent management, data export/deletion]

## 8. Testing Strategy
### 8.1 Unit Tests
[Coverage targets per layer, what to test]

### 8.2 Integration Tests
[Database tests, API tests, repository tests]

### 8.3 UI Tests
[Compose test rules, screen tests, navigation tests]

### 8.4 TDD Workflow
[Red-green-refactor cycle, test-first requirements]

## 9. Build & CI/CD
### 9.1 Build Variants
[Debug, release, staging, product flavors]

### 9.2 Signing Configuration
[Keystore management, environment variables]

### 9.3 ProGuard/R8 Rules
[Keep rules, optimization settings]

### 9.4 CI Pipeline
[Build, test, lint, release workflow]

## 10. Performance Requirements
### 10.1 Startup Time
[Cold start target, splash screen]

### 10.2 Memory Budget
[Per-screen limits, leak detection]

### 10.3 Network Efficiency
[Request batching, pagination, compression]

### 10.4 Battery Optimization
[Background work limits, WorkManager usage]

## 11. Dependency Catalog
[Complete version catalog (libs.versions.toml format) with ALL dependencies, versions, and bundle definitions]

## 12. Implementation Roadmap
### Phase 1: Foundation [weeks 1-2]
### Phase 2: Core Features [weeks 3-4]
### Phase 3: Polish & Testing [weeks 5-6]
### Phase 4: Release Preparation [week 7]
```

## Critical Rules

1. **Requirements only** — NO Kotlin code, NO XML, NO Gradle snippets. Describe WHAT, not HOW.
2. **Complete in one file** — deliver the entire blueprint via a single `create_file` operation. Never use multiple `str_replace` calls for revisions.
3. **Tech stack is fixed** — use the exact versions specified in section 2.1 unless the user explicitly overrides.
4. **Every feature needs acceptance criteria** — no feature is specified without testable criteria.
5. **Sealed interfaces for state** — always specify UiState as sealed interface pattern in feature specs.
6. **Dutch market awareness** — if targeting NL, include AVG compliance, Dutch locale support, iDEAL payment integration where relevant.
7. **File naming** — save as `[appname]_blueprint_v1.md` in the current working directory.

## Quality Checklist (verify before delivering)

- [ ] All 12 sections present and substantive
- [ ] Tech stack versions are correct (2026 stack)
- [ ] Every feature has user stories + acceptance criteria
- [ ] Navigation graph covers all screens
- [ ] Database schema matches feature requirements
- [ ] Testing strategy covers all layers
- [ ] No implementation code anywhere
- [ ] Dependency catalog is complete
- [ ] Implementation roadmap is realistic
