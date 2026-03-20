#!/bin/bash
# session-init.sh
# Runs at the start of every Claude Code session.
# Detects Android project context and provides relevant information.

# Check if we're in an Android project
IS_ANDROID=false

if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
    if grep -q "android" build.gradle.kts 2>/dev/null || grep -q "android" build.gradle 2>/dev/null; then
        IS_ANDROID=true
    fi
fi

if [ -f "settings.gradle.kts" ] || [ -f "settings.gradle" ]; then
    IS_ANDROID=true
fi

if [ "$IS_ANDROID" = false ]; then
    exit 0
fi

# We're in an Android project — gather context
echo "🤖 Android Forge — Session initialized"
echo ""

# Check for blueprint
BLUEPRINT=$(find . -maxdepth 1 -name "*_blueprint_*.md" 2>/dev/null | sort -V | tail -1)
if [ -n "$BLUEPRINT" ]; then
    echo "📋 Blueprint found: $BLUEPRINT"
fi

# Check for CLAUDE.md
if [ -f ".claude/CLAUDE.md" ] || [ -f "CLAUDE.md" ]; then
    echo "📄 CLAUDE.md found — project conventions loaded"
fi

# Check Kotlin version
if [ -f "gradle/libs.versions.toml" ]; then
    KOTLIN_VER=$(grep '^kotlin\s*=' "gradle/libs.versions.toml" 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')
    AGP_VER=$(grep '^agp\s*=' "gradle/libs.versions.toml" 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')
    if [ -n "$KOTLIN_VER" ]; then
        echo "🔧 Kotlin: $KOTLIN_VER | AGP: ${AGP_VER:-unknown}"
    fi
fi

# Count modules
MODULE_COUNT=$(grep -c 'include(' settings.gradle.kts 2>/dev/null || echo "0")
if [ "$MODULE_COUNT" -gt 0 ]; then
    echo "📦 Modules: $MODULE_COUNT"
fi

# Check for TODO/FIXME count
TODO_COUNT=$(grep -rn "TODO\|FIXME" --include="*.kt" app/ feature/ core/ 2>/dev/null | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
    echo "📝 Open TODOs/FIXMEs: $TODO_COUNT"
fi

# Check last build status
if [ -d "app/build" ]; then
    if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
        BUILD_DATE=$(stat -c %Y "app/build/outputs/apk/debug/app-debug.apk" 2>/dev/null || stat -f %m "app/build/outputs/apk/debug/app-debug.apk" 2>/dev/null)
        if [ -n "$BUILD_DATE" ]; then
            echo "🏗️  Last debug APK built: $(date -d @$BUILD_DATE 2>/dev/null || date -r $BUILD_DATE 2>/dev/null)"
        fi
    fi
fi

echo ""
exit 0
