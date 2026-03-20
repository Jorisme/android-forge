# /team-review — Parallel Code Review with Specialist Agents

You are orchestrating a parallel code review using Claude Code Agent Teams. Multiple specialist reviewers examine the codebase simultaneously, each from a different perspective, then findings are synthesized into a unified report.

**Prerequisite**: Agent Teams must be enabled:
```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Input

$ARGUMENTS can contain:
- A branch name, commit SHA, or PR reference to review
- "full" — review the entire codebase
- A feature module path (e.g., `feature/home/`)
- Nothing — defaults to reviewing changes on current branch vs main

## Workflow

### Step 1: Determine Scope

```bash
# If on feature branch
git diff main...HEAD --stat

# If specific commit
git show --stat $COMMIT

# If full review
find app/ core/ feature/ -name "*.kt" | head -50
```

### Step 2: Spawn Review Team

Create an agent team with 4-5 specialist reviewers:

```
Create an agent team for parallel Android code review.

Review scope: [determined in step 1]

Spawn these specialist reviewers:

- Teammate "architecture": Review for Clean Architecture compliance.
  Check: layer violations (presentation importing data), dependency direction,
  module boundaries, repository pattern adherence, UiState/Event pattern consistency.
  Reference the android-conventions skill for architecture rules.
  Flag any ViewModel that imports from core/data/ or any feature that depends on another feature.

- Teammate "compose-quality": Review all Compose UI code.
  Check: state hoisting, recomposition performance (missing keys in LazyColumn,
  unstable parameters, inline object allocation), accessibility (contentDescription,
  touch targets, TalkBack), preview annotations, Material 3 theme token usage.
  Reference the compose-specialist agent for patterns.

- Teammate "testing": Review test quality and coverage.
  Check: do all ViewModels have tests? Are all UiState variants tested? 
  Are acceptance criteria from the blueprint covered? Is TDD pattern followed
  (tests exist for all business logic)? Are there Thread.sleep() calls?
  Is MockK used correctly (mocking interfaces not implementations)?
  Reference the tdd-enforcer agent for standards.

- Teammate "security": Review for security and privacy issues.
  Check: hardcoded secrets/API keys, exposed sensitive data (BSN if healthcare),
  proper encryption (Room with SQLCipher if medical data), network security config,
  ProGuard keep rules, permission usage, FLAG_SECURE where needed.
  Also check AVG/GDPR compliance for any personal data handling.

- Teammate "gradle-deps": Review build configuration and dependencies.
  Check: version catalog completeness, KSP/Kotlin version alignment,
  no hardcoded versions in build.gradle.kts, proper plugin ordering,
  no deprecated dependencies (KAPT, kotlin-android-extensions),
  ProGuard rules for all annotation-processed libraries.
  Reference the gradle-doctor agent for compatibility rules.

Each reviewer: examine ONLY your specialty area. Report findings as:
- CRITICAL: Must fix before merge (bugs, security issues, architecture violations)
- WARNING: Should fix (performance, best practice violations)
- SUGGESTION: Nice to have (style, optimization opportunities)

Include file:line references for every finding.
When done, message the team lead with your findings summary.
```

### Step 3: Synthesize

After all reviewers report, synthesize into a unified review:

```markdown
# Code Review Report

## Summary
- Reviewers: 5 parallel specialists
- Scope: [branch/files reviewed]
- Date: [today]

| Reviewer | Critical | Warning | Suggestion |
|----------|----------|---------|------------|
| Architecture | X | X | X |
| Compose Quality | X | X | X |
| Testing | X | X | X |
| Security | X | X | X |
| Gradle/Deps | X | X | X |
| **Total** | **X** | **X** | **X** |

## Critical Issues (must fix)
1. [Finding from reviewer] — `file:line`
   **Impact**: [what breaks]
   **Fix**: [how to fix]

## Warnings (should fix)
1. [Finding] — `file:line`

## Suggestions (nice to have)
1. [Finding] — `file:line`

## Verdict: [APPROVE / NEEDS CHANGES / BLOCK]
```

### Step 4: Auto-Fix Option

After presenting the report, ask:
> "Want me to auto-fix the Critical and Warning issues? I'll create a fix commit for each category."

If approved, fix issues in priority order (Critical first), running tests after each fix.

## Quick Review Presets

### `/team-review --security-only`
Spawn only the security reviewer — faster and cheaper for targeted audits.

### `/team-review --pre-release`  
Add a 6th reviewer focused on release readiness (version numbers, debug flags, TODO markers, string resources).

### `/team-review --blueprint fundradar_blueprint_v2.md`
Add a reviewer that checks implementation against blueprint acceptance criteria.

## When to Use Teams vs Subagents for Review

| Scenario | Use |
|----------|-----|
| Quick review of 1-2 files | Subagents (cheaper) |
| Full feature module review | Agent Teams |
| Pre-release audit | Agent Teams |
| Single-aspect review (just security) | Single subagent |
| Blueprint compliance check | Agent Teams (needs cross-referencing) |

## Rules

- Reviewers NEVER modify code — they only report findings
- Each reviewer stays in their lane — no duplicate findings across reviewers
- Blueprint acceptance criteria are the ultimate test of correctness
- Security findings are always Critical, never downgraded
- If reviewing healthcare code, the security reviewer must check FHIR/medical data handling
