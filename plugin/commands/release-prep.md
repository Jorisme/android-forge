# /release-prep — Prepare Android App for Play Store Release

You are preparing an Android app for Google Play Store release. This command runs a comprehensive pre-release checklist and fixes issues.

## Input

$ARGUMENTS may contain a version name (e.g., "1.0.0") or "check-only" to audit without making changes.

## Release Checklist

Execute each section. Mark items as ✅ (pass), ⚠️ (warning), or ❌ (fail). Fix ❌ items automatically where possible.

### 1. Version & Build Numbers

```bash
# Extract current version info
grep -E "versionCode|versionName|namespace" app/build.gradle.kts
```

- [ ] `versionName` matches the target release version
- [ ] `versionCode` is incremented from the last release
- [ ] `namespace` is set and matches package structure
- [ ] `compileSdk` and `targetSdk` are current (36+)
- [ ] `minSdk` is documented and intentional

### 2. Signing Configuration

- [ ] Release keystore exists and is NOT in version control
- [ ] Signing config references environment variables (not hardcoded paths/passwords)
- [ ] `.gitignore` includes `*.keystore`, `*.jks`, `keystore.properties`
- [ ] `signingConfigs.release` is properly configured in `build.gradle.kts`

### 3. ProGuard / R8

```bash
# Check R8 configuration
cat app/proguard-rules.pro 2>/dev/null
grep -r "minifyEnabled\|shrinkResources\|proguard" app/build.gradle.kts
```

- [ ] `minifyEnabled = true` for release build type
- [ ] `shrinkResources = true` for release build type
- [ ] ProGuard rules include keeps for: Hilt, Room entities, Kotlin Serialization models, Retrofit interfaces
- [ ] No `minifyEnabled = true` on debug build type

### 4. Permissions Audit

```bash
# Extract all permissions
grep -r "uses-permission" app/src/main/AndroidManifest.xml
# Check for debug-only permissions
grep -r "INTERNET\|ACCESS_NETWORK_STATE\|CAMERA\|LOCATION\|STORAGE\|READ_CONTACTS" app/src/main/AndroidManifest.xml
```

- [ ] All permissions are actually used by features
- [ ] No overly broad permissions (e.g., `READ_CONTACTS` when only name is needed)
- [ ] Runtime permissions are requested at point of use, not at startup
- [ ] `INTERNET` permission is present if networking is used

### 5. Security Audit

- [ ] No API keys or secrets hardcoded in source (search for common patterns)
- [ ] No `android:debuggable="true"` in release manifest
- [ ] No `android:allowBackup="true"` unless intentional (with `android:fullBackupContent` rules)
- [ ] Network security config restricts cleartext traffic (`android:usesCleartextTraffic="false"`)
- [ ] Certificate pinning configured for critical API endpoints (if applicable)

```bash
# Scan for potential secrets
grep -rn "api_key\|apiKey\|secret\|password\|token" --include="*.kt" --include="*.xml" --include="*.properties" . | grep -v "test/" | grep -v ".gradle/" | grep -v "build/"
```

### 6. Privacy & Compliance (AVG/GDPR)

- [ ] Privacy policy URL configured
- [ ] Data collection disclosure prepared for Play Console
- [ ] User consent mechanism implemented (if collecting analytics/personal data)
- [ ] Data deletion endpoint or mechanism available
- [ ] No unnecessary data collection
- [ ] Third-party SDK data practices documented

### 7. Quality Checks

```bash
# Run all tests
./gradlew test 2>&1 | tail -20

# Lint check
./gradlew lintRelease 2>&1 | tail -30

# Check for TODO/FIXME/HACK markers
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.kt" app/ feature/ core/ | head -20
```

- [ ] All unit tests pass
- [ ] No critical or error-level lint issues
- [ ] No TODO/FIXME markers in production code
- [ ] No unused resources (`./gradlew lintRelease` catches these)
- [ ] String resources extracted (no hardcoded strings in composables)

### 8. Performance

- [ ] Baseline profiles generated (`./gradlew generateBaselineProfile` if configured)
- [ ] No `StrictMode` violations in release (StrictMode should be debug-only)
- [ ] Large assets optimized (images compressed, unused assets removed)
- [ ] App size is reasonable for the feature set

### 9. Play Store Assets

- [ ] App icon meets Play Store requirements (512x512 PNG)
- [ ] Feature graphic prepared (1024x500)
- [ ] Screenshots for required device types
- [ ] Short description (max 80 chars)
- [ ] Full description (max 4000 chars)
- [ ] Category selected
- [ ] Content rating questionnaire completed

### 10. Build Verification

```bash
# Build release APK/Bundle
./gradlew bundleRelease 2>&1 | tail -20

# Check output
ls -la app/build/outputs/bundle/release/ 2>/dev/null
```

- [ ] Release bundle builds successfully
- [ ] Bundle is signed
- [ ] Bundle size is within expectations

## Output

Generate a **Release Readiness Report**:

```markdown
# Release Readiness Report — [App Name] v[version]
Date: [today]

## Summary
- ✅ Passed: [count]
- ⚠️ Warnings: [count]  
- ❌ Failed: [count]
- **Status: [READY / NOT READY]**

## Details
[Per-section results with specifics]

## Auto-Fixed Issues
[List of issues that were automatically resolved]

## Manual Action Required
[Issues that need human intervention]

## Recommended Next Steps
1. [step]
```

## Rules

- If "check-only" mode, report issues but don't fix anything.
- Always build the release bundle at the end to verify everything works together.
- Be extra cautious with signing — never create or modify keystores without explicit user approval.
- Dutch locale: verify `values-nl/strings.xml` exists if the app targets the Netherlands.
