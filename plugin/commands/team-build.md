# /team-build — Parallel Feature Implementation with Agent Teams

You are orchestrating a team of Claude Code agents to implement Android features in parallel. This command leverages Claude Code's Agent Teams feature for maximum development speed.

**Prerequisite**: Agent Teams must be enabled:
```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Input

$ARGUMENTS should contain either:
- A feature name or list of features to implement, OR
- A path to a blueprint file + phase number (e.g., `fundradar_blueprint_v2.md phase 2`)

## Workflow

### Step 1: Analyze & Decompose

Read the blueprint (if provided) or analyze the current project. Identify features that can be implemented in parallel by checking:
- **File independence**: features that touch different modules/files
- **No data dependencies**: feature B doesn't need feature A's output to compile
- **Interface stability**: shared interfaces are already defined or can be defined upfront

### Step 2: Define Contracts First

Before spawning teammates, define the shared interfaces that teammates will code against. This prevents merge conflicts:

- Repository interfaces in `core/domain/`
- Shared data models in `core/domain/model/`
- Navigation routes in `app/navigation/`
- Shared UiState patterns

Write these interface files yourself (as team lead) before delegating implementation.

### Step 3: Spawn Team

Create an agent team with this structure. Optimal team size is 2-4 teammates:

```
Create an agent team for parallel Android feature development.

Team structure:
- Teammate "data-layer": Implement Room entities, DAOs, Retrofit services, and repository 
  implementations in core/data/ for: [feature list]. Follow TDD — write repository tests first.
  Read the blueprint at [path] sections 3 (Data Architecture) and 11 (Dependencies).
  Use the android-conventions skill for stack versions and patterns.

- Teammate "feature-[name]": Implement [feature] in feature/[name]/ module. 
  Build ViewModel, UiState, Screen composable following MVVM+UDF pattern.
  Write ViewModel tests first (TDD). Use the compose-specialist agent for UI patterns.
  Read blueprint section 4.[x] for acceptance criteria.
  Code against the interfaces defined in core/domain/ — do NOT modify domain interfaces.

- Teammate "feature-[name2]": [same pattern for second feature]

Coordination rules:
- Each teammate owns their module — no cross-module file edits
- Data-layer teammate finishes first, then feature teammates consume the implementations
- Use shared task list for dependency tracking
- When done, each teammate runs tests in their module: ./gradlew :feature:[name]:test
```

### Step 4: Monitor & Coordinate

As team lead:
- Track progress via the shared task list
- Resolve interface conflicts if they arise
- Run integration checks when teammates report completion:

```bash
./gradlew assembleDebug  # Full build to catch integration issues
./gradlew test           # All unit tests
```

### Step 5: Merge & Verify

After all teammates complete:
1. Review changes per module
2. Run the full test suite
3. Check for lint issues: `./gradlew lintDebug`
4. Verify navigation integration works
5. Report summary of what was built

## Team Patterns for Android Development

### Pattern A: Layer-Parallel (best for new features)
```
Lead:       Define interfaces in core/domain/
Teammate 1: Implement core/data/ (Room + Retrofit + Repositories)
Teammate 2: Implement feature/feature-a/ (ViewModel + Screen)
Teammate 3: Implement feature/feature-b/ (ViewModel + Screen)
```

### Pattern B: Feature-Parallel (best for independent features)
```
Lead:       Coordinate, define shared navigation
Teammate 1: Full-stack feature A (data + domain + presentation)
Teammate 2: Full-stack feature B (data + domain + presentation)
Teammate 3: Full-stack feature C (data + domain + presentation)
```
Use git worktrees for file isolation when features touch overlapping files.

### Pattern C: TDD-Pair (best for complex single feature)
```
Lead:       Write acceptance tests from blueprint criteria
Teammate 1: Implement code to pass the tests (data + domain)
Teammate 2: Implement UI + ViewModel to pass UI tests
```

## Cost Awareness

Agent Teams use 3-4x more tokens than a single session. Use teams only when:
- ✅ Multiple independent features to implement
- ✅ Blueprint phase has 3+ parallel-ready features
- ✅ Time savings justify the token cost
- ❌ Single feature with sequential dependencies
- ❌ Bug fixes or small changes
- ❌ Features that all modify the same files

## Rules

- ALWAYS define domain interfaces before spawning implementers
- NEVER assign the same file to multiple teammates
- Each teammate must run their module's tests before marking work complete
- Blueprint is the source of truth — teammates must read the relevant sections
- Keep teams to 2-4 teammates — larger teams create more coordination overhead than speed gains
- Use subagents (not teams) for quick parallel tasks like multi-file code review within one feature
