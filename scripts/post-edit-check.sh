#!/bin/bash
# post-edit-check.sh
# Runs automatically after Claude writes or edits a file.
# Performs lightweight quality checks on Kotlin/Gradle files.

# Get the edited file path from environment (Claude Code passes this)
FILE_PATH="${CLAUDE_FILE_PATH:-}"

# Exit silently if no file path or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# --- Kotlin file checks ---
if [ "$EXT" = "kt" ] || [ "$EXT" = "kts" ]; then

    # Check for common anti-patterns
    ISSUES=""

    # Check for GlobalScope usage
    if grep -qn "GlobalScope" "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}\n⚠️  GlobalScope detected in $FILE_PATH — use viewModelScope or a scoped coroutine instead"
    fi

    # Check for non-null assertion (!!)
    if grep -qn '!!' "$FILE_PATH" 2>/dev/null; then
        COUNT=$(grep -c '!!' "$FILE_PATH" 2>/dev/null)
        ISSUES="${ISSUES}\n⚠️  $COUNT non-null assertion(s) (!!) in $FILE_PATH — prefer safe calls (?.) or requireNotNull()"
    fi

    # Check for hardcoded colors in Compose files
    if grep -qn 'Color(0x' "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}\n⚠️  Hardcoded color values in $FILE_PATH — use MaterialTheme.colorScheme tokens"
    fi

    # Check for missing content descriptions on icons
    if grep -q 'Icon(' "$FILE_PATH" 2>/dev/null; then
        if grep -q 'contentDescription = null' "$FILE_PATH" 2>/dev/null; then
            ISSUES="${ISSUES}\n⚠️  Icon with null contentDescription in $FILE_PATH — add accessibility description"
        fi
    fi

    # Check for mutable state exposed from ViewModel
    if grep -qn 'val.*MutableStateFlow\|val.*MutableState<' "$FILE_PATH" 2>/dev/null; then
        if ! grep -q 'private' "$FILE_PATH" 2>/dev/null || grep -qn '^[[:space:]]*val.*MutableStateFlow' "$FILE_PATH" 2>/dev/null; then
            ISSUES="${ISSUES}\n⚠️  Potentially exposed MutableStateFlow in $FILE_PATH — ensure it's private with a public StateFlow"
        fi
    fi

    # Check for Thread.sleep in test files
    if echo "$FILE_PATH" | grep -q "test/" 2>/dev/null; then
        if grep -qn 'Thread.sleep' "$FILE_PATH" 2>/dev/null; then
            ISSUES="${ISSUES}\n⚠️  Thread.sleep() in test file $FILE_PATH — use runTest with advanceTimeBy() instead"
        fi
    fi

    # Output issues if any found
    if [ -n "$ISSUES" ]; then
        echo -e "\n🔍 Android Forge — Post-edit checks:$ISSUES"
    fi
fi

# --- Gradle file checks ---
if [ "$EXT" = "kts" ] && echo "$FILE_PATH" | grep -q "build.gradle" 2>/dev/null; then

    ISSUES=""

    # Check for hardcoded dependency versions
    if grep -qn 'implementation(".*:.*:[0-9]' "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}\n⚠️  Hardcoded dependency version in $FILE_PATH — use version catalog (libs.versions.toml)"
    fi

    # Check for deprecated KAPT usage
    if grep -qn 'kapt(' "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}\n⚠️  KAPT detected in $FILE_PATH — migrate to KSP (kapt is deprecated for Hilt 2.50+)"
    fi

    if [ -n "$ISSUES" ]; then
        echo -e "\n🔍 Android Forge — Gradle checks:$ISSUES"
    fi
fi

# --- XML checks ---
if [ "$EXT" = "xml" ] && echo "$FILE_PATH" | grep -q "AndroidManifest" 2>/dev/null; then

    ISSUES=""

    # Check for debuggable in manifest
    if grep -qn 'android:debuggable="true"' "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}\n⚠️  android:debuggable=true in AndroidManifest — this should only be in debug variant"
    fi

    # Check for allowBackup without fullBackupContent
    if grep -q 'android:allowBackup="true"' "$FILE_PATH" 2>/dev/null; then
        if ! grep -q 'android:fullBackupContent' "$FILE_PATH" 2>/dev/null; then
            ISSUES="${ISSUES}\n⚠️  allowBackup=true without fullBackupContent rules — specify what to include/exclude"
        fi
    fi

    if [ -n "$ISSUES" ]; then
        echo -e "\n🔍 Android Forge — Manifest checks:$ISSUES"
    fi
fi

exit 0
