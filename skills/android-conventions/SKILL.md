---
name: android-conventions
description: >
  Android development conventions and standards for modern 2026 Kotlin/Compose stack. 
  Auto-invoke when writing Kotlin code for Android, configuring Gradle build files, creating 
  Compose UI components, setting up Hilt dependency injection, defining Room database schemas, 
  implementing MVVM architecture, or any Android-related development task. Covers coding style, 
  architecture patterns, naming conventions, project structure, and quality standards.
---

# Android Development Conventions (2026 Stack)

## Tech Stack — Non-Negotiable Versions

These versions are fixed for project consistency. Do NOT deviate without explicit user approval.

| Component | Version | Gradle Catalog Key |
|-----------|---------|-------------------|
| Kotlin | 2.3.10 | `kotlin` |
| AGP | 9.0.1 | `agp` |
| KSP | 2.3.10-1.0.x | `ksp` (must match Kotlin) |
| Hilt | 2.55 | `hilt` |
| Room | 2.7.1 | `room` |
| Compose BOM | 2026.03.00 | `composeBom` |
| Coroutines | 1.10.x | `coroutines` |
| Navigation | Compose (type-safe) | `navigation-compose` |
| Retrofit | 2.11.x | `retrofit` |
| OkHttp | 4.12.x | `okhttp` |
| Coil | 3.x | `coil` |
| Kotlin Serialization | 1.8.x | `serialization` |
| JDK | 21 | Required by AGP 9 |
| minSdk | 26 | Android 8.0 Oreo |
| targetSdk | 36 | Latest |
| compileSdk | 36 | Latest |

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

### Coroutines

- Use `viewModelScope` in ViewModels
- `Dispatchers.IO` for disk/network, `Dispatchers.Default` for CPU
- Never use `GlobalScope`
- Use `Flow` for reactive streams, `suspend fun` for one-shot operations
- Handle cancellation properly — check `isActive` in long loops

### Dependency Injection (Hilt)

```kotlin
// Module — in core/data
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
