# /blueprint-review — Validate and Improve an Existing Blueprint

You are reviewing an Android app blueprint for completeness, consistency, and quality. Your goal is to find gaps, contradictions, and improvements.

## Input

$ARGUMENTS should be a path to a blueprint `.md` file. If not provided, search the current directory for `*_blueprint_*.md` files and ask which one to review.

## Review Process

Read the entire blueprint first. Then evaluate each dimension:

### 1. Structural Completeness

Check that ALL required sections are present and substantive:
- [ ] Project Overview (vision, audience, value prop, KPIs)
- [ ] Technical Foundation (stack, architecture, modules, SDK versions)
- [ ] Data Architecture (database schema, API, sync, caching)
- [ ] Feature Specifications (user stories, acceptance criteria, UiState, edge cases)
- [ ] Navigation Architecture (graph, patterns, back stack)
- [ ] UI/UX Specifications (design system, theme, components, accessibility)
- [ ] Security & Privacy (auth, encryption, compliance)
- [ ] Testing Strategy (unit, integration, UI, TDD workflow)
- [ ] Build & CI/CD (variants, signing, ProGuard, pipeline)
- [ ] Performance Requirements (startup, memory, network, battery)
- [ ] Dependency Catalog (complete libs.versions.toml)
- [ ] Implementation Roadmap (phased, realistic timelines)

### 2. Tech Stack Validation

- Kotlin version is 2.3.10 or explicitly justified if different
- AGP version is 9.0.1 or justified
- KSP version matches Kotlin version
- Compose BOM is 2026.x
- Hilt 2.55, Room 2.7.1
- No deprecated libraries (e.g., Kotlin synthetics, ViewBinding for Compose-only apps, AsyncTask)
- No conflicting library choices (e.g., both Dagger and Koin)

### 3. Feature Consistency

For each feature, verify:
- User story follows "As a [user], I want [goal], so that [benefit]" format
- Acceptance criteria are testable (can write a test for each one)
- UiState sealed interface covers: Loading, Success, Error, and feature-specific states
- Navigation route is defined in the navigation section
- Required data is available in the data architecture section
- No feature references undefined data models or APIs

### 4. Architecture Coherence

- Every Repository interface in domain has an implementation referenced in data
- Every ViewModel maps to a feature screen in navigation
- Database entities support all features that need local data
- API endpoints cover all features that need remote data
- Dependency injection modules are complete

### 5. Testing Feasibility

- Every acceptance criterion can be translated to a test
- Testing approach matches architecture (e.g., ViewModel tests mock repositories, not DAOs)
- UI tests reference actual composable names from feature specs
- Coverage targets are realistic

### 6. Implementation Code Check

**CRITICAL**: Blueprint should contain ZERO implementation code. Flag any:
- Kotlin code blocks
- XML layouts
- Gradle script content beyond version catalog format
- SQL statements (schema descriptions are fine, raw SQL is not)

## Output

Generate a **Blueprint Review Report**:

```markdown
# Blueprint Review — [App Name]

## Overall Score: [A/B/C/D/F]

### Scoring Criteria
- A: Complete, consistent, ready for implementation
- B: Minor gaps, can proceed with noted improvements
- C: Significant gaps, revisions needed before implementation
- D: Major structural issues, substantial rework needed
- F: Incomplete, not usable as implementation guide

## Section Scores
| Section | Score | Issues |
|---------|-------|--------|
| [each section] | ✅/⚠️/❌ | [brief] |

## Critical Issues (must fix)
1. [Issue + recommended fix]

## Improvements (should fix)
1. [Issue + recommended fix]

## Suggestions (nice to have)
1. [Suggestion]

## Missing Elements
- [List of missing items]

## Contradictions Found
- [List of inconsistencies between sections]
```

After presenting the report, ask if the user wants you to apply the fixes. If yes, produce the revised blueprint as a single new file (never patch with str_replace).

## Rules

- Be thorough but constructive — the goal is to improve, not to criticize.
- The tech stack versions are not suggestions — they're the standard. Flag deviations.
- A blueprint with code in it is automatically rated C or below.
- Always check cross-references between sections (e.g., a feature that needs GPS but no location permission in security section).
