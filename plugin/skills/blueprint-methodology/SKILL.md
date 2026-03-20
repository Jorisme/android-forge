---
name: blueprint-methodology
description: >
  Blueprint-driven Android development methodology. Auto-invoke when creating app blueprints,
  requirements documents, app specifications, or architecture documents. Also invoke when
  discussing app planning, requirements gathering, or when the user mentions "blueprint",
  "requirements document", "app spec", or "functional design" in an Android context.
  Covers the complete methodology for writing requirements-only specification documents
  that serve as input for AI-powered implementation agents.
---

# Blueprint Methodology for Android App Development

## What is a Blueprint?

A blueprint is a **comprehensive, requirements-only specification document** that serves as the single source of truth for implementing an Android app. It is designed to be consumed by AI coding agents (Claude Code) and human developers alike.

**A blueprint is NOT**:
- A design document with mockups (though it describes what should be on screen)
- A codebase or boilerplate generator
- A tutorial or learning resource
- An optional planning artifact — it's the mandatory first step

## Core Principles

### 1. Requirements Only — No Implementation Code

The blueprint describes WHAT the app does and WHY, never HOW at the code level.

**Allowed**:
- Architecture patterns ("MVVM with Clean Architecture, 3 layers")
- Data models ("User has fields: id, name, email, createdAt")
- API contracts ("GET /users returns list of User objects")
- State descriptions ("Loading, Success, Error, Empty states")
- Acceptance criteria ("Given no internet, when refreshing, then show cached data with offline banner")

**Forbidden**:
- Kotlin/Java code snippets
- XML layouts
- Gradle build scripts (except version catalog format for dependency listing)
- SQL statements (describe schema, don't write CREATE TABLE)

### 2. Complete in One File

The entire blueprint MUST be deliverable as a single Markdown file. This ensures:
- AI agents can load the full context in one read
- No cross-file references that might get lost
- Version control is simple (one file = one version)
- The blueprint can be shared as a single attachment

### 3. Reference Template Structure

All blueprints follow the same 12-section structure (see the `/blueprint` command for the full template). This consistency means:
- AI agents learn the structure once and apply it to every project
- Reviews can systematically check for completeness
- Teams have a shared vocabulary for discussing app architecture

### 4. Tech Stack is Predetermined

The tech stack is fixed at the latest stable versions. This eliminates:
- Time spent evaluating alternatives
- Version compatibility research during implementation
- Inconsistency across projects

Current stack (2026):
- Kotlin 2.3.10, AGP 9.0.1, Hilt 2.55, Room 2.7.1, Compose BOM 2026.x

### 5. Revisions are Additive, Never Reductive

When revising a blueprint:
- The revised version must be **equal or larger** than the original
- Sections don't get summarized or shortened — they get refined and expanded
- Always produce the complete revised file in a single operation
- Never apply revisions as individual text replacements (causes drift and shrinkage)
- Name revised files with incremented version: `_v1.md` → `_v2.md`

## Blueprint Creation Workflow

```
1. INTERVIEW    →  /app-interview "my app idea"
                   Socratic questioning to expose hidden assumptions
                   Output: Requirements Summary

2. BLUEPRINT    →  /blueprint MyApp
                   Transform requirements into full blueprint
                   Output: myapp_blueprint_v1.md

3. REVIEW       →  /blueprint-review myapp_blueprint_v1.md
                   Validate completeness, consistency, quality
                   Output: Review Report + optional v2

4. SCAFFOLD     →  /new-android-app myapp_blueprint_v1.md
                   Generate project structure from blueprint
                   Output: Working project skeleton

5. IMPLEMENT    →  Feature-by-feature TDD implementation
                   Following the blueprint's roadmap phases
```

## Quality Standards for Blueprints

### Section Completeness Checklist

Each section must contain substantive content — no "TBD", no "To be decided", no placeholder text.

| Section | Minimum Content |
|---------|----------------|
| Project Overview | Vision paragraph, target audience description, 3+ KPIs |
| Technical Foundation | Complete version table, architecture diagram description, module list |
| Data Architecture | All entities with fields, all API endpoints, sync strategy |
| Feature Specs | Per feature: user story, 3+ acceptance criteria, UiState variants, edge cases |
| Navigation | All screens listed, all routes defined, back stack behavior |
| UI/UX | Color palette (hex values), typography scale, spacing system |
| Security | Auth flow, encryption approach, compliance requirements |
| Testing | Coverage targets per layer, TDD workflow description |
| Build & CI | Build variants, signing approach, CI steps |
| Performance | Startup target, memory budget, network strategy |
| Dependencies | Complete libs.versions.toml in TOML format |
| Roadmap | Phased plan with week estimates, feature-to-phase mapping |

### Feature Specification Standard

Every feature MUST include ALL of these elements:

```markdown
### 4.x [Feature Name]

#### User Story
As a [persona], I want [capability], so that [benefit].

#### Acceptance Criteria
1. Given [precondition], when [action], then [expected result]
2. Given [precondition], when [action], then [expected result]
3. ... (minimum 3 per feature)

#### Screen Specification
- Layout description (what's visible in each state)
- Interactive elements (buttons, inputs, gestures)
- Empty state behavior
- Loading state behavior
- Error state behavior

#### State Management
```
sealed interface [Feature]UiState {
    data object Loading : [Feature]UiState
    data class Success(val data: [Type]) : [Feature]UiState
    data class Error(val message: String) : [Feature]UiState
    // Feature-specific states
}
```

#### Navigation
- Route: [route definition]
- Entry points: [where users navigate from]
- Exit points: [where users can go next]
- Deep link: [if applicable]

#### Error Handling
- Network failure: [behavior]
- Validation error: [behavior]
- Authorization error: [behavior]

#### Edge Cases
- [Edge case 1 and expected behavior]
- [Edge case 2 and expected behavior]
```

### Cross-Reference Validation

A good blueprint has internal consistency. These cross-references must align:

- Every feature's data needs → covered by data architecture entities/endpoints
- Every screen → reachable via navigation graph
- Every entity → used by at least one feature
- Every API endpoint → consumed by at least one repository
- Every dependency → referenced by at least one module
- Every roadmap phase → contains only features that its dependencies support

## Common Blueprint Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| Vague acceptance criteria | Untestable features | Use Given/When/Then format |
| Missing error states | Crashes in production | Add Error variant to every UiState |
| No offline strategy | App unusable without network | Define offline-first approach |
| Dependencies without versions | Build failures | Use exact version numbers |
| Features without edge cases | Bugs in unusual flows | Test with: no data, slow network, rotation, process death |
| Code in blueprint | Constrains implementation | Describe behavior, not code |
| Shrunken revision | Lost requirements | Always produce complete revised file |

## Blueprint File Naming

```
[appname]_blueprint_v[N].md

Examples:
fundradar_blueprint_v1.md
daycoach_blueprint_v2.md
saxbuddy_blueprint_v3.md
```

## Using Blueprints with Claude Code Agents

The blueprint is designed to be loaded as context for Claude Code sessions. Best practices:

1. **Start every session** by pointing Claude to the blueprint: "Read `fundradar_blueprint_v3.md` — this is the specification."
2. **Implement feature by feature** following the roadmap phases
3. **Reference acceptance criteria** when writing tests (TDD)
4. **Update the blueprint** if implementation reveals missing requirements (create new version)
5. **Never deviate from the blueprint** without updating it first — the blueprint is the contract
