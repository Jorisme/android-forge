# 🔨 Android Forge

**Blueprint-driven Android development orchestration for Claude Code.**

Android Forge is a Claude Code plugin that brings structured, repeatable, high-quality Android app development to your terminal. It combines a proven blueprint methodology with specialized AI agents, auto-invoked skills, and quality hooks — all tuned for the modern 2026 Kotlin/Compose stack.

## Why Android Forge?

Building Android apps with AI coding agents works best when the agent has a comprehensive specification to work from. Without one, you get inconsistent architecture, missing edge cases, and code that doesn't hold together.

Android Forge solves this with a **blueprint-first methodology**:

1. **Interview** → Socratic questioning exposes hidden assumptions before any code is written
2. **Blueprint** → A complete requirements-only specification document (no code, all decisions)
3. **Scaffold** → Project skeleton generated from the blueprint with correct architecture
4. **Implement** → Feature-by-feature TDD development guided by the blueprint
5. **Release** → Comprehensive pre-release checklist catches issues before the Play Store

## Installation

```bash
# In Claude Code:
/plugin marketplace add https://github.com/menno/android-forge
/plugin install android-forge
```

That's it. Skills auto-activate when you work on Android code. Agents are available when Claude needs specialized expertise. Hooks run quality checks automatically.

## What's Included

### Slash Commands (6)

| Command | Purpose |
|---------|---------|
| `/app-interview` | Socratic requirements discovery — 5-phase deep interview before writing any code |
| `/blueprint` | Generate a complete 12-section app blueprint from requirements |
| `/blueprint-review` | Validate and score an existing blueprint for completeness and consistency |
| `/new-android-app` | Scaffold a full project structure from a blueprint |
| `/build-check` | Diagnose and fix Android build failures |
| `/release-prep` | Comprehensive Play Store release readiness checklist |

### Agents (4)

| Agent | Specialization |
|-------|---------------|
| `blueprint-architect` | Requirements specification, architecture design, tech stack validation |
| `compose-specialist` | Jetpack Compose UI, Material 3, state management, accessibility, animation |
| `gradle-doctor` | Build diagnostics, dependency resolution, version compatibility, optimization |
| `tdd-enforcer` | Test-Driven Development, JUnit 5, MockK, Turbine, Compose UI testing |

### Skills (3, auto-invoked)

| Skill | Triggers On |
|-------|------------|
| `android-conventions` | Any Kotlin/Android/Gradle/Compose code editing |
| `blueprint-methodology` | Blueprint creation, requirements documents, app planning |
| `fhir-android` | Healthcare data, FHIR, HL7, zibs, Dutch healthcare IT |

### Hooks (2)

| Hook | Event | Action |
|------|-------|--------|
| Post-edit checker | After file write/edit | Scans for anti-patterns (GlobalScope, !!, hardcoded colors, exposed MutableState, etc.) |
| Session initializer | Session start | Detects Android project, shows blueprint status, Kotlin version, module count, TODOs |

## Tech Stack (2026)

Android Forge enforces a consistent, modern tech stack across all projects:

| Component | Version |
|-----------|---------|
| Kotlin | 2.3.10 |
| AGP | 9.0.1 |
| Hilt | 2.55 |
| Room | 2.7.1 |
| Compose BOM | 2026.x |
| KSP | 2.3.10-1.0.x |
| JDK | 21 |
| minSdk | 26 |
| targetSdk / compileSdk | 36 |

## Quick Start

### Start a new app from scratch

```
/app-interview "ETF portfolio tracker for Dutch investors"
```

Answer the 5 phases of questions. When done, you'll get a Requirements Summary.

```
/blueprint FundRadar
```

This generates `fundradar_blueprint_v1.md` — a complete 12-section specification.

```
/blueprint-review fundradar_blueprint_v1.md
```

Review for completeness. Fix any issues, producing `_v2` if needed.

```
/new-android-app fundradar_blueprint_v2.md
```

Scaffolds the full project structure with build files, modules, theme, and CLAUDE.md.

### Fix a broken build

```
/build-check
```

Or with a specific error:

```
/build-check "Duplicate class kotlin.collections.jdk8.CollectionsJDK8Kt found in modules..."
```

### Prepare for release

```
/release-prep 1.0.0
```

Runs the full 10-section checklist and generates a Release Readiness Report.

## Blueprint Methodology

The blueprint methodology is the heart of Android Forge. Key principles:

- **Requirements only** — blueprints contain no implementation code
- **Complete in one file** — a single .md file with all 12 sections
- **Revisions are additive** — revised blueprints are always equal or larger
- **Single-file delivery** — always produce via one `create_file`, never multiple `str_replace`
- **Tech stack is predetermined** — no time wasted on library selection

See the `blueprint-methodology` skill for the full documentation.

## Healthcare / FHIR Support

Android Forge includes specialized support for Dutch healthcare Android development:

- HL7 FHIR R4 resource handling patterns
- Dutch healthcare profiles (nictiz nl-core-*)
- Zib (zorginformatiebouwsteen) to FHIR mapping reference
- BSN handling rules (privacy, masking, no-logging)
- AVG/GDPR Article 9 compliance for medical data
- SMART on FHIR authentication flow
- MedMij PGO requirements
- Zorgviewer ecosystem integration (RIVO-Noord)

This skill auto-activates whenever healthcare-related terms appear in your conversation.

## Project Structure

```
android-forge/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/                     # Slash commands
│   ├── app-interview.md          # /app-interview
│   ├── blueprint.md              # /blueprint
│   ├── blueprint-review.md       # /blueprint-review
│   ├── new-android-app.md        # /new-android-app
│   ├── build-check.md            # /build-check
│   └── release-prep.md           # /release-prep
├── agents/                       # Specialized subagents
│   ├── blueprint-architect.md
│   ├── compose-specialist.md
│   ├── gradle-doctor.md
│   └── tdd-enforcer.md
├── skills/                       # Auto-invoked skills
│   ├── android-conventions/
│   │   └── SKILL.md
│   ├── blueprint-methodology/
│   │   └── SKILL.md
│   └── fhir-android/
│       └── SKILL.md
├── hooks/
│   └── hooks.json                # Event handlers
├── scripts/
│   ├── post-edit-check.sh        # Post-edit quality checks
│   └── session-init.sh           # Session initialization
└── README.md
```

## Customization

### Adding Your Own Commands

Create a new `.md` file in the `commands/` directory. It becomes available as `/filename` immediately.

### Adding Your Own Agents

Create a new `.md` file in the `agents/` directory with YAML frontmatter:

```markdown
---
name: my-agent
description: When and why Claude should invoke this agent.
---

Agent system prompt goes here...
```

### Adding Your Own Skills

Create a new directory in `skills/` with a `SKILL.md` file:

```
skills/my-skill/
└── SKILL.md     # With YAML frontmatter including name and description
```

### Modifying Hooks

Edit `hooks/hooks.json` to add or change event handlers. Supported events:
- `PostToolUse` (with matcher for specific tools like Write, Edit, Bash)
- `SessionStart`
- `Stop`

## Version History

### v1.0.0
- Initial release
- 6 commands, 4 agents, 3 skills, 2 hooks
- Full blueprint methodology
- 2026 tech stack (Kotlin 2.3.10, AGP 9.0.1)
- Healthcare/FHIR support with Dutch standards

## License

MIT

## Author

Built by Menno — freelance Senior Business Analyst / Functional Designer specializing in Dutch government and healthcare IT. Designed to bridge the gap between functional requirements and AI-powered Android development.
