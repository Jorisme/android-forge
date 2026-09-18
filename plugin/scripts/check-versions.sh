#!/bin/bash
# check-versions.sh
# Fetches the latest stable versions of key Android dependencies from Maven/Google repos.
# Called by session-init.sh or manually via: ./scripts/check-versions.sh
#
# Outputs a version report comparing current project versions (from libs.versions.toml)
# against the latest available stable releases.

TOML_FILE="gradle/libs.versions.toml"
CACHE_FILE=".android-forge-versions-cache"
CACHE_MAX_AGE=86400  # 24 hours in seconds

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Curl flag fix-up:
#   On Windows, the Git Bash curl binary uses Schannel as its TLS backend. Schannel performs
#   a strict revocation check (CRL/OCSP) that fails with CRYPT_E_NO_REVOCATION_CHECK whenever
#   the revocation servers are unreachable (corporate firewalls, captive networks, etc.).
#   The result is that `curl https://dl.google.com` exits non-zero even though the network
#   is healthy — and this script then falls back to "No internet connection — using hardcoded
#   reference versions". The fix is `--ssl-no-revoke`, which is Schannel-only; applying it on
#   OpenSSL/LibreSSL curl prints "option unknown" and aborts. So we detect the backend first.
CURL_EXTRA_FLAGS=""
if curl --version 2>/dev/null | grep -qi "schannel"; then
    CURL_EXTRA_FLAGS="--ssl-no-revoke"
fi

# Check if cache is fresh enough
use_cache() {
    if [ -f "$CACHE_FILE" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
            return 0
        fi
    fi
    return 1
}

# Fetch latest stable version from Google Maven (for AndroidX libraries)
fetch_google_maven() {
    local group="$1"
    local artifact="$2"
    local group_path="${group//.//}"
    local url="https://dl.google.com/android/maven2/${group_path}/${artifact}/maven-metadata.xml"
    local result
    result=$(curl -s $CURL_EXTRA_FLAGS --connect-timeout 5 "$url" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        # Extract latest release version (skip alpha, beta, rc, dev)
        echo "$result" | grep -oP '<version>\K[^<]+' | \
            grep -v -iE '(alpha|beta|rc|dev|eap|snapshot)' | \
            sort -V | tail -1
    fi
}

# Fetch latest stable version from Maven Central
fetch_maven_central() {
    local group="$1"
    local artifact="$2"
    local url="https://search.maven.org/solrsearch/select?q=g:${group}+AND+a:${artifact}&rows=20&core=gav&wt=json"
    local result
    result=$(curl -s $CURL_EXTRA_FLAGS --connect-timeout 5 "$url" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        echo "$result" | grep -oP '"v":"[^"]+' | sed 's/"v":"//' | \
            grep -v -iE '(alpha|beta|rc|dev|eap|snapshot)' | \
            sort -V | tail -1
    fi
}

# Read current version from libs.versions.toml.
#
# Robust against two real-world TOML conventions:
#   1. Naming variants — projects use bare (`room`), `androidx-` prefixed (`androidx-room`),
#      `kotlinx-` prefixed (`kotlinx-coroutines`), and the camelCase ↔ kebab-case mismatch
#      between the script's COMPONENTS array (camelCase, e.g. `composeBom`) and TOML keys
#      (kebab-case, e.g. `compose-bom`). We try all six variants.
#   2. Multi-quote lines — version-pin lines often carry inline comments with quoted text
#      (`hilt = "2.59.2"  # bumped from 2.56 — throws "Android BaseExtension not found"`).
#      The original sed `s/.*"\(.*\)".*/\1/` is greedy and grabs the LAST quoted segment
#      (the comment), reporting `"Android BaseExtension not found"` as the version. We
#      anchor to the FIRST quoted segment instead with `s/^[^"]*"\([^"]*\)".*/\1/`.
read_current() {
    local key="$1"
    if [ -f "$TOML_FILE" ]; then
        local kebab
        kebab=$(echo "$key" | sed 's/\([A-Z]\)/-\L\1/g')
        local pattern result
        for pattern in "$key" "androidx-$key" "kotlinx-$key" "$kebab" "androidx-$kebab" "kotlinx-$kebab"; do
            result=$(grep "^${pattern}\s*=" "$TOML_FILE" 2>/dev/null | head -1 | sed 's/^[^"]*"\([^"]*\)".*/\1/')
            if [ -n "$result" ]; then
                echo "$result"
                return
            fi
        done
    fi
}

# Compare two version strings
compare_versions() {
    local current="$1"
    local latest="$2"
    if [ -z "$current" ]; then
        echo "MISSING"
    elif [ -z "$latest" ]; then
        echo "UNKNOWN"
    elif [ "$current" = "$latest" ]; then
        echo "OK"
    else
        # Simple comparison: if latest is different and sorts higher, it's outdated
        local higher
        higher=$(printf '%s\n%s' "$current" "$latest" | sort -V | tail -1)
        if [ "$higher" = "$latest" ] && [ "$current" != "$latest" ]; then
            echo "UPDATE"
        else
            echo "OK"
        fi
    fi
}

echo "🔍 Android Forge — Version Check"
echo ""

if use_cache && [ "$1" != "--force" ]; then
    echo "(using cached results, run with --force to refresh)"
    cat "$CACHE_FILE"
    exit 0
fi

# Check for internet connectivity
if ! curl -s $CURL_EXTRA_FLAGS --connect-timeout 3 "https://dl.google.com" >/dev/null 2>&1; then
    echo "⚠️  No internet connection — using hardcoded reference versions"
    echo ""
    echo "Reference stack (March 2026):"
    echo "  Kotlin:       2.3.20"
    echo "  AGP:          9.1.0"
    echo "  KSP:          2.3.6"
    echo "  Gradle:       9.3.1"
    echo "  Hilt:         2.56"
    echo "  Room:         2.8.4"
    echo "  Compose BOM:  2026.03.00"
    echo "  Navigation:   2.9.7"
    echo "  Lifecycle:    2.10.0"
    exit 0
fi

echo "Fetching latest stable versions..."
echo ""

# Define components to check: key|group|artifact|display_name
COMPONENTS=(
    "kotlin|org.jetbrains.kotlin|kotlin-stdlib|Kotlin"
    "agp|com.android.tools.build|gradle|AGP"
    "ksp|com.google.devtools.ksp|symbol-processing-api|KSP"
    "hilt|com.google.dagger|hilt-android|Hilt (Dagger)"
    "room|androidx.room|room-runtime|Room"
    "composeBom|androidx.compose|compose-bom|Compose BOM"
    "navigation|androidx.navigation|navigation-compose|Navigation"
    "lifecycle|androidx.lifecycle|lifecycle-runtime-ktx|Lifecycle"
    "coroutines|org.jetbrains.kotlinx|kotlinx-coroutines-core|Coroutines"
)

# Build report
REPORT=""
HAS_UPDATES=false

for component in "${COMPONENTS[@]}"; do
    IFS='|' read -r key group artifact display <<< "$component"
    
    current=$(read_current "$key")
    
    # Choose Maven source
    if [[ "$group" == androidx.* ]]; then
        latest=$(fetch_google_maven "$group" "$artifact")
    else
        latest=$(fetch_maven_central "$group" "$artifact")
    fi
    
    status=$(compare_versions "$current" "$latest")
    
    case "$status" in
        "OK")
            line="${GREEN}✅${NC} ${display}: ${current}"
            ;;
        "UPDATE")
            line="${YELLOW}⬆️${NC}  ${display}: ${current:-?} → ${latest}"
            HAS_UPDATES=true
            ;;
        "MISSING")
            line="${RED}❌${NC} ${display}: not in version catalog (latest: ${latest:-?})"
            ;;
        "UNKNOWN")
            line="❓ ${display}: ${current} (could not fetch latest)"
            ;;
    esac
    
    REPORT="${REPORT}${line}\n"
done

# Output report
echo -e "$REPORT"

# Compatibility notes
echo "📋 Compatibility Notes:"
echo "  • AGP 9.0+ has built-in Kotlin — remove kotlin-android plugin"
echo "  • KSP uses independent versioning (not tied to Kotlin version)"
echo "  • KSP1 incompatible with Kotlin 2.3+ / AGP 9+ — use KSP2 only"
echo "  • Compose compiler bundled with Kotlin 2.0+ — no separate version"
echo ""

if [ "$HAS_UPDATES" = true ]; then
    echo "💡 Run /build-check after updating versions to verify compatibility."
fi

# Cache results (strip color codes for cache)
echo -e "$REPORT" | sed 's/\x1b\[[0-9;]*m//g' > "$CACHE_FILE" 2>/dev/null

exit 0
