---
name: android-conventions
description: >
  Android development conventions and standards for modern 2026 Kotlin/Compose stack. 
  Auto-invoke when writing Kotlin code for Android, configuring Gradle build files, creating 
  Compose UI components, setting up Hilt dependency injection, defining Room database schemas, 
  implementing MVVM architecture, or any Android-related development task. Covers coding style, 
  architecture patterns, naming conventions, project structure, and quality standards.
  IMPORTANT: On session start, run scripts/check-versions.sh to verify versions are current.
---

# Android Development Conventions (2026 Stack)

## Dynamic Version Management

**Before starting work on any Android project**, run the version check script to ensure you're using the latest compatible versions:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-versions.sh
```

This fetches the latest stable versions from Maven/Google Maven and compares them against the project's `libs.versions.toml`. Results are cached for 24 hours. Use `--force` to bypass cache.

If the script is unavailable or offline, use the **reference versions** below as the baseline. These are verified compatible as of March 2026.

## Tech Stack — Reference Versions (March 2026)

These are the latest stable, mutually compatible versions. Always verify via `check-versions.sh` before hardcoding.

| Component | Version | Gradle Catalog Key | Notes |
|-----------|---------|-------------------|-------|
| Kotlin | 2.3.20 | `kotlin` | Latest stable (March 16, 2026) |
| AGP | 9.1.0 | `agp` | Built-in Kotlin support — see below |
| KSP | 2.3.6 | `ksp` | Independent versioning since KSP2 |
| Gradle | 9.3.1 | (wrapper) | Required by AGP 9.1 |
| Hilt (Dagger) | 2.56 | `hilt` | KSP-only (KAPT removed) |
| Room | 2.8.4 | `room` | Uses KSP processor |
| Compose BOM | 2026.03.00 | `composeBom` | Controls all Compose lib versions |
| Navigation | 2.9.7 | `navigation` | Type-safe routes with Serialization |
| Lifecycle | 2.10.0 | `lifecycle` | Includes compose extensions |
| Coroutines | 1.10.x | `coroutines` | Kotlin-aligned |
| Retrofit | 2.11.x | `retrofit` | With Kotlin Serialization converter |
| OkHttp | 4.12.x | `okhttp` | HTTP engine |
| Coil | 3.x | `coil` | Compose-native image loading |
| Kotlin Serialization | 1.8.x | `serialization` | JSON processing |
| JDK | 21 | — | Required by AGP 9.x |
| minSdk | 26 | — | Android 8.0 Oreo |
| targetSdk | 36 | — | Latest |
| compileSdk | 36 | — | Latest |

## Critical: AGP 9.0+ Changes

AGP 9.0 introduced **built-in Kotlin support**. This changes how you configure Android projects.

### What Changed

1. **No more `kotlin-android` plugin** — AGP handles Kotlin compilation natively
2. **No more `kotlinOptions` block** — use `compilerOptions` in the `kotlin` block instead
3. **KSP1 is dead** — KSP2 is the only option for Kotlin 2.3+ / AGP 9+
4. **New DSL interfaces** — old `BaseExtension` APIs removed
5. **Compose compiler** — bundled with Kotlin 2.0+ (no separate version needed)

### Plugin Configuration (AGP 9.1+)

**Root build.gradle.kts:**
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    // NO kotlin-android plugin — AGP handles it
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.hilt) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
```

**App module build.gradle.kts:**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    // NO kotlin-android needed
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "nl.package.app"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        targetSdk = 36
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}
```

### KSP2 — Independent Versioning

KSP now uses its own version numbers (e.g., `2.3.6`), NOT tied to Kotlin version. The old format `kotlin-version-ksp-version` (e.g., `2.3.10-1.0.x`) is obsolete.

```toml
# OLD (wrong):
ksp = "2.3.20-1.0.x"

# NEW (correct):
ksp = "2.3.6"
```

KSP2 is the default since early 2025. KSP1 is NOT compatible with Kotlin 2.3+ or AGP 9+.

### Opt-Out Flags (temporary, removed in AGP 10)

If migrating gradually, you can temporarily opt out:
```properties
# gradle.properties — TEMPORARY, will be removed in AGP 10 (mid-2026)
android.builtInKotlin=false
android.newDsl=false
```

Do NOT use these flags for new projects.

## Architecture

### Layer Separation (Clean Architecture)

```
presentation (feature modules)
    │ depends on
    ▼
domain (core/domain)
    ▲ depends on
    │
data (core/data)
```

**Rules**:
- `domain` has ZERO Android dependencies (pure Kotlin)
- `presentation` NEVER imports from `data` layer
- `data` implements interfaces defined in `domain`
- Dependencies flow inward: presentation → domain ← data

### Module Structure

```
app/                    → Application, MainActivity, NavGraph, Theme
core/
  ├── common/           → Result wrapper, extensions, shared DI modules
  ├── domain/           → Repository interfaces, UseCases, domain models
  └── data/             → Repository implementations, Room, Retrofit, DTOs
feature/
  ├── feature-a/        → Screen, ViewModel, UiState, feature DI
  └── feature-b/
```

### MVVM + UDF Pattern

```
User Action → Event → ViewModel → Repository → DataSource
                         │
                    Updates UiState (StateFlow)
                         │
                    Compose UI observes and recomposes
```

**ViewModel structure**:
```kotlin
@HiltViewModel
class FeatureViewModel @Inject constructor(
    private val useCase: GetDataUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow<FeatureUiState>(FeatureUiState.Loading)
    val uiState: StateFlow<FeatureUiState> = _uiState.asStateFlow()

    fun onEvent(event: FeatureEvent) {
        when (event) {
            is FeatureEvent.LoadData -> loadData()
            is FeatureEvent.Refresh -> refresh()
        }
    }
}
```

### UiState Pattern

Always use sealed interface:

```kotlin
sealed interface FeatureUiState {
    data object Loading : FeatureUiState
    data class Success(val data: DataType) : FeatureUiState
    data class Error(val message: String, val canRetry: Boolean = true) : FeatureUiState
}
```

### Events Pattern

```kotlin
sealed interface FeatureEvent {
    data object LoadData : FeatureEvent
    data object Refresh : FeatureEvent
    data class ItemClicked(val id: String) : FeatureEvent
    data class SearchQueryChanged(val query: String) : FeatureEvent
}
```

## Kotlin Conventions

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `ItemRepository`, `UserViewModel` |
| Functions | camelCase | `getUserById()`, `calculateTotal()` |
| Properties | camelCase | `isLoading`, `itemCount` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT`, `BASE_URL` |
| Composables | PascalCase | `ItemCard()`, `UserAvatar()` |
| Packages | lowercase | `nl.app.feature.home` |
| Test classes | [Class]Test | `UserViewModelTest` |
| Test functions | backtick descriptive | `` `should emit loading state initially`() `` |

### Code Style

- **Explicit types on public API**: `fun getUser(): Flow<User>` not `fun getUser() = repository.getUser()`
- **Expression bodies** for single-expression functions: `fun isValid() = name.isNotBlank()`
- **Trailing commas** on multi-line parameter lists
- **Named arguments** when calling functions with 3+ parameters
- **No wildcard imports** — import specific classes
- **`when` over `if-else` chains** for 3+ branches
- **Avoid `!!`** — use `?.let { }`, `?: return`, or `requireNotNull()`
- **Name-based destructuring** (Kotlin 2.3.20+): use named destructuring for clarity in complex data classes

### Coroutines

- Use `viewModelScope` in ViewModels
- `Dispatchers.IO` for disk/network, `Dispatchers.Default` for CPU
- Never use `GlobalScope`
- Use `Flow` for reactive streams, `suspend fun` for one-shot operations
- Handle cancellation properly — check `isActive` in long loops

### Dependency Injection (Hilt with KSP)

```kotlin
// Module — in core/data (uses KSP, NOT KAPT)
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository
}

// Provides — for third-party classes
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideRetrofit(): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.BASE_URL)
        .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
        .build()
}
```

**Hilt plugin order** in build.gradle.kts:
```kotlin
plugins {
    alias(libs.plugins.android.library)  // 1st
    alias(libs.plugins.ksp)              // 2nd — before Hilt
    alias(libs.plugins.hilt)             // 3rd — after KSP
}
```

## Compose Conventions

### Screen Structure (3 Layers)

```kotlin
// Layer 1: Route (navigation entry, owns ViewModel)
@Composable
fun FeatureRoute(
    viewModel: FeatureViewModel = hiltViewModel(),
    onNavigateToDetail: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    FeatureScreen(uiState = uiState, onEvent = viewModel::onEvent, onNavigateToDetail = onNavigateToDetail)
}

// Layer 2: Screen (stateless, testable, has Scaffold)
@Composable
fun FeatureScreen(
    uiState: FeatureUiState,
    onEvent: (FeatureEvent) -> Unit,
    onNavigateToDetail: (String) -> Unit
) {
    Scaffold(topBar = { /* ... */ }) { padding ->
        FeatureContent(uiState = uiState, onEvent = onEvent, modifier = Modifier.padding(padding))
    }
}

// Layer 3: Content (pure rendering, easy to preview)
@Composable
fun FeatureContent(
    uiState: FeatureUiState,
    onEvent: (FeatureEvent) -> Unit,
    modifier: Modifier = Modifier
) {
    when (uiState) {
        FeatureUiState.Loading -> LoadingIndicator(modifier)
        is FeatureUiState.Success -> ItemList(items = uiState.data, modifier = modifier)
        is FeatureUiState.Error -> ErrorMessage(message = uiState.message, onRetry = { onEvent(FeatureEvent.Refresh) }, modifier = modifier)
    }
}
```

### Preview Annotations

Every screen composable must have previews for:
- Light theme
- Dark theme
- Large font (fontScale = 2.0)
- Each UiState variant

```kotlin
@Preview(name = "Light")
@Preview(name = "Dark", uiMode = Configuration.UI_MODE_NIGHT_YES)
@Preview(name = "Large Font", fontScale = 2.0f)
@Composable
private fun FeatureScreenPreview() {
    AppTheme {
        FeatureScreen(uiState = FeatureUiState.Success(sampleData), onEvent = {})
    }
}
```

### Modifier Conventions

- First parameter after required data: `modifier: Modifier = Modifier`
- Chain modifiers in logical order: layout → appearance → interaction
- Pass `modifier` to the root composable only

## Data Layer Conventions

### Room

- Entities use `@Entity` with explicit `tableName`
- DAOs return `Flow<List<T>>` for observable queries
- Use `@Upsert` over `@Insert(onConflict = REPLACE)` when possible
- Schema version in a constant: `companion object { const val VERSION = 1 }`
- Migrations are explicit — never `fallbackToDestructiveMigration()` in production
- Room 2.8+ generates Kotlin code by default — ensure `room.generateKotlin` KSP arg is set

```kotlin
ksp {
    arg("room.schemaLocation", "${projectDir}/schemas")
    arg("room.incremental", "true")
    arg("room.generateKotlin", "true")
}
```

### Retrofit

- Interfaces with suspend functions
- Use `@Serializable` data classes for request/response (Kotlin Serialization)
- Centralized error handling via interceptor or Result wrapper

### Repository Pattern

```kotlin
// Interface in domain
interface UserRepository {
    fun getUsers(): Flow<List<User>>
    suspend fun refreshUsers()
    suspend fun getUserById(id: String): User?
}

// Implementation in data
class UserRepositoryImpl @Inject constructor(
    private val dao: UserDao,
    private val api: UserApi
) : UserRepository {
    override fun getUsers(): Flow<List<User>> =
        dao.getAll().map { entities -> entities.map { it.toDomain() } }

    override suspend fun refreshUsers() {
        val remote = api.getUsers()
        dao.upsertAll(remote.map { it.toEntity() })
    }
}
```

## Error Handling

- Use a sealed `Result` wrapper in core/common:

```kotlin
sealed interface AppResult<out T> {
    data class Success<T>(val data: T) : AppResult<T>
    data class Error(val exception: Throwable, val message: String? = null) : AppResult<Nothing>
}
```

- Network errors → user-friendly message, log the exception
- Database errors → should never happen in normal flow, log as error
- Validation errors → show inline on the relevant field

## Version Catalog Template (libs.versions.toml)

```toml
[versions]
# Core — verify with check-versions.sh
kotlin = "2.3.20"
agp = "9.1.0"
ksp = "2.3.6"
hilt = "2.56"
room = "2.8.4"

# Compose
composeBom = "2026.03.00"

# AndroidX
lifecycle = "2.10.0"
navigation = "2.9.7"
coroutines = "1.10.1"
serialization = "1.8.1"

# Networking
retrofit = "2.11.0"
okhttp = "4.12.0"
coil = "3.1.0"

# Testing
junit5 = "5.11.4"
mockk = "1.13.16"
turbine = "1.2.0"

[libraries]
# Compose (managed by BOM)
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-ui-graphics = { group = "androidx.compose.ui", name = "ui-graphics" }
compose-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }

# Hilt
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-android-compiler", version.ref = "hilt" }
hilt-navigation-compose = { group = "androidx.hilt", name = "hilt-navigation-compose", version = "1.3.0" }

# Room
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }

# Lifecycle
lifecycle-runtime-compose = { group = "androidx.lifecycle", name = "lifecycle-runtime-compose", version.ref = "lifecycle" }
lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }

# Navigation
navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigation" }

# Networking
retrofit = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }
okhttp = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp" }
okhttp-logging = { group = "com.squareup.okhttp3", name = "logging-interceptor", version.ref = "okhttp" }
serialization-json = { group = "org.jetbrains.kotlinx", name = "kotlinx-serialization-json", version.ref = "serialization" }
retrofit-serialization = { group = "com.squareup.retrofit2", name = "converter-kotlinx-serialization", version.ref = "retrofit" }

# Image Loading
coil-compose = { group = "io.coil-kt.coil3", name = "coil-compose", version.ref = "coil" }

# Coroutines
coroutines-core = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-core", version.ref = "coroutines" }
coroutines-android = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-android", version.ref = "coroutines" }
coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutines" }

# Testing
junit5 = { group = "org.junit.jupiter", name = "junit-jupiter", version.ref = "junit5" }
mockk = { group = "io.mockk", name = "mockk", version.ref = "mockk" }
turbine = { group = "app.cash.turbine", name = "turbine", version.ref = "turbine" }

[bundles]
compose = ["compose-ui", "compose-ui-graphics", "compose-ui-tooling-preview", "compose-material3"]
networking = ["retrofit", "okhttp", "okhttp-logging", "serialization-json", "retrofit-serialization"]
testing = ["junit5", "mockk", "turbine", "coroutines-test"]

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
```

## Version Control

- Conventional commits: `feat:`, `fix:`, `chore:`, `test:`, `refactor:`, `docs:`
- Feature branches from `main`: `feature/add-user-profile`
- No direct commits to `main`
- Every PR must have passing tests

## Quality Gates

Before any PR or release:
1. `./gradlew test` — all unit tests pass
2. `./gradlew lintDebug` — no errors (warnings documented)
3. `./gradlew ktlintCheck` — code style compliance
4. No `TODO`, `FIXME`, or `HACK` in code targeting release
5. All new features have corresponding tests
