---
name: emulator-testing
description: >
  Android emulator testing via ADB from Claude Code terminal. Auto-invoke when the user mentions
  emulator, device testing, ADB, logcat, screenshot, UI testing on device, install APK, run on 
  emulator, app crash, runtime testing, manual testing, visual testing, or "test on device".
  Covers emulator management, APK deployment, UI interaction, screenshot capture, logcat 
  monitoring, instrumented test execution, and performance profiling — all via ADB commands
  that Claude Code can execute directly from VS Code's terminal.
---

# Android Emulator Testing via ADB

Claude Code can interact with Android emulators and physical devices through ADB (Android Debug Bridge) commands executed directly in the terminal. This enables building, deploying, testing, inspecting, and debugging apps without leaving VS Code.

## Prerequisites

### Windows (Menno's Setup)

Ensure these are on your PATH:

```powershell
# Check ADB is available
adb version

# Check emulator tool is available  
emulator -list-avds

# If not found, add to PATH (typical locations):
# C:\Users\<user>\AppData\Local\Android\Sdk\platform-tools   (adb)
# C:\Users\<user>\AppData\Local\Android\Sdk\emulator          (emulator)
```

If `ANDROID_HOME` or `ANDROID_SDK_ROOT` is not set:
```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path += ";$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator"
```

### Verify Setup

```bash
# List available emulators (AVDs)
emulator -list-avds

# List connected devices/emulators
adb devices

# Should show something like:
# List of devices attached
# emulator-5554   device
```

## Emulator Management

### List Available AVDs

```bash
emulator -list-avds
# Example output:
# Pixel_8_API_36
# Medium_Phone_API_35
```

### Start an Emulator

```powershell
# Start in background (Windows)
Start-Process -FilePath "emulator" -ArgumentList "-avd Pixel_8_API_36 -no-snapshot-load" -WindowStyle Hidden

# Or from bash/terminal:
emulator -avd Pixel_8_API_36 -no-snapshot-load &
```

**Useful emulator flags:**
- `-no-snapshot-load` — cold boot (clean state)
- `-no-window` — headless mode (CI/no GUI needed)  
- `-no-audio` — disable audio (faster startup)
- `-gpu swiftshader_indirect` — software rendering (if GPU issues)
- `-wipe-data` — factory reset the AVD

### Wait for Emulator to Boot

```bash
# Block until device is fully booted
adb wait-for-device
adb shell getprop sys.boot_completed
# Returns "1" when ready

# Full boot wait loop:
adb wait-for-device
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do sleep 2; done
echo "Emulator ready"
```

On Windows PowerShell:
```powershell
adb wait-for-device
do { Start-Sleep -Seconds 2 } while ((adb shell getprop sys.boot_completed 2>$null) -ne "1")
Write-Host "Emulator ready"
```

### Stop Emulator

```bash
adb emu kill
# Or kill specific device:
adb -s emulator-5554 emu kill
```

## Build, Install & Launch

### Build and Install APK

```bash
# Build debug APK
./gradlew assembleDebug

# Install on connected device/emulator
adb install -r app/build/outputs/apk/debug/app-debug.apk
# -r = replace existing app (keep data)
# -t = allow test packages
```

Or in one step:
```bash
./gradlew installDebug
```

### Launch the App

```bash
# Launch main activity
adb shell am start -n "nl.package.app/.MainActivity"

# Launch with specific intent
adb shell am start -n "nl.package.app/.MainActivity" -a android.intent.action.VIEW -d "https://example.com/deeplink"

# Force stop first (clean restart)
adb shell am force-stop nl.package.app
adb shell am start -n "nl.package.app/.MainActivity"
```

### Uninstall

```bash
adb uninstall nl.package.app
# Keep data:
adb uninstall -k nl.package.app
```

## Screenshots & Screen Recording

### Take a Screenshot

```bash
# Capture to device, then pull to PC
adb shell screencap /sdcard/screen.png
adb pull /sdcard/screen.png ./screenshot.png
adb shell rm /sdcard/screen.png

# One-liner (pipe directly):
adb exec-out screencap -p > screenshot.png
```

**When to take screenshots:**
- After each navigation step to verify UI state
- When a test fails to capture the failure state
- Before and after user interactions to verify changes
- On crash to see the last visible state

### Screen Recording

```bash
# Record up to 180 seconds
adb shell screenrecord /sdcard/recording.mp4
# Press Ctrl+C to stop, then:
adb pull /sdcard/recording.mp4 ./recording.mp4
adb shell rm /sdcard/recording.mp4

# With time limit:
adb shell screenrecord --time-limit 30 /sdcard/recording.mp4
```

## UI Inspection & Interaction

### Dump UI Hierarchy (UI Automator)

```bash
# Dump current screen's UI tree as XML
adb shell uiautomator dump /sdcard/ui_dump.xml
adb pull /sdcard/ui_dump.xml ./ui_dump.xml
adb shell rm /sdcard/ui_dump.xml

# Read the dump directly:
adb exec-out uiautomator dump /dev/tty
```

The XML contains all visible elements with:
- `text` — displayed text
- `resource-id` — element ID (matches testTag or resource ID)
- `content-desc` — accessibility description
- `bounds` — coordinates `[left,top][right,bottom]`
- `clickable`, `enabled`, `focused` — interaction state

**Use this to find element coordinates for tap/swipe commands.**

### Tap on Screen

```bash
# Tap at coordinates (x, y)
adb shell input tap 540 1200

# To find coordinates: dump UI, find the element's bounds,
# calculate center: x = (left + right) / 2, y = (top + bottom) / 2
```

### Type Text

```bash
# Type text (spaces must be escaped as %s)
adb shell input text "hello%sworld"

# For special characters, use key events:
adb shell input keyevent KEYCODE_AT        # @
adb shell input keyevent KEYCODE_ENTER     # Enter
adb shell input keyevent KEYCODE_TAB       # Tab
```

### Swipe / Scroll

```bash
# Swipe from (x1,y1) to (x2,y2) in milliseconds
adb shell input swipe 540 1500 540 500 300    # Scroll up
adb shell input swipe 540 500 540 1500 300    # Scroll down
adb shell input swipe 800 960 200 960 300     # Swipe left
```

### Press Buttons

```bash
adb shell input keyevent KEYCODE_BACK         # Back button
adb shell input keyevent KEYCODE_HOME         # Home button  
adb shell input keyevent KEYCODE_APP_SWITCH   # Recent apps
adb shell input keyevent KEYCODE_VOLUME_UP    # Volume up
adb shell input keyevent KEYCODE_POWER        # Power button
```

### Rotate Screen

```bash
# Disable auto-rotate first
adb shell settings put system accelerometer_rotation 0

# Portrait
adb shell settings put system user_rotation 0
# Landscape
adb shell settings put system user_rotation 1
# Reverse portrait
adb shell settings put system user_rotation 2
# Reverse landscape
adb shell settings put system user_rotation 3
```

## Logcat Monitoring

### Basic Logcat

```bash
# All logs (very noisy)
adb logcat

# Filter by tag
adb logcat -s MyApp:V

# Filter by priority (V=verbose, D=debug, I=info, W=warn, E=error, F=fatal)
adb logcat *:E    # Errors and fatals only

# Filter by package (Android 7+)
adb logcat --pid=$(adb shell pidof nl.package.app)
```

### Crash Detection

```bash
# Watch for crashes (FATAL EXCEPTION)
adb logcat *:E | grep -i "FATAL\|AndroidRuntime\|CRASH\|Exception"

# Save crash log to file
adb logcat -d *:E > crash_log.txt

# Clear logcat buffer first (start fresh)
adb logcat -c
# Then run your test, then capture:
adb logcat -d > full_log.txt
```

### Structured Log Capture

```bash
# Clear log, run action, capture result
adb logcat -c
adb shell am start -n "nl.package.app/.MainActivity"
sleep 5
adb logcat -d -s "nl.package.app:V" > startup_log.txt
```

## Running Instrumented Tests on Emulator

### Run All Instrumented Tests

```bash
./gradlew connectedDebugAndroidTest
```

### Run Specific Test Class

```bash
./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=nl.package.app.feature.home.HomeScreenTest
```

### Run Specific Test Method

```bash
./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=nl.package.app.feature.home.HomeScreenTest#showsItemList_whenSuccess
```

### Run Tests via ADB Directly

```bash
# Install test APK
adb install -r app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk

# Run all tests
adb shell am instrument -w -r nl.package.app.test/androidx.test.runner.AndroidJUnitRunner

# Run specific class
adb shell am instrument -w -r -e class nl.package.app.feature.home.HomeScreenTest nl.package.app.test/androidx.test.runner.AndroidJUnitRunner
```

### Capture Test Results

```bash
# Gradle captures results in:
# app/build/reports/androidTests/connected/index.html
# app/build/outputs/androidTest-results/connected/

# Open report (Windows):
start app\build\reports\androidTests\connected\index.html
```

## Performance Profiling

### Memory Info

```bash
# App memory usage
adb shell dumpsys meminfo nl.package.app

# Summary only
adb shell dumpsys meminfo nl.package.app | head -30
```

### CPU Info

```bash
# Current CPU usage
adb shell top -n 1 | grep nl.package.app
```

### Battery Stats

```bash
# Reset battery stats
adb shell dumpsys batterystats --reset

# Run your test scenario...

# Get battery report
adb shell dumpsys batterystats nl.package.app
```

### Startup Time

```bash
# Measure cold start time
adb shell am force-stop nl.package.app
adb shell am start-activity -W -n "nl.package.app/.MainActivity"
# Look for "TotalTime" in output
```

### Network Stats

```bash
adb shell dumpsys netstats detail | grep nl.package.app
```

## Observe-Think-Act Testing Loop

When Claude Code tests an app on the emulator, follow this systematic loop:

### 1. OBSERVE — Capture Current State

```bash
# Take screenshot
adb exec-out screencap -p > current_state.png

# Dump UI hierarchy
adb exec-out uiautomator dump /dev/tty

# Check logcat for errors
adb logcat -d *:E | tail -20
```

### 2. THINK — Analyze What You See

From the UI dump XML:
- What screen are we on? (check visible text, resource-ids)
- What elements are interactive? (clickable=true)
- What's the expected state vs actual state?
- Are there any errors in logcat?

### 3. ACT — Perform Interaction

```bash
# Example: tap on a button identified in UI dump
# bounds="[200,800][880,920]" → center = (540, 860)
adb shell input tap 540 860

# Wait for UI to settle
sleep 1
```

### 4. VERIFY — Confirm Result

```bash
# Screenshot after action
adb exec-out screencap -p > after_action.png

# Check UI changed as expected
adb exec-out uiautomator dump /dev/tty

# Check for crashes
adb logcat -d *:E | grep -i "FATAL\|Exception" | tail -5
```

Repeat this loop for each test step.

## Common Test Scenarios

### Verify App Launches Without Crash

```bash
adb logcat -c
adb shell am force-stop nl.package.app
adb shell am start-activity -W -n "nl.package.app/.MainActivity"
sleep 3
CRASHES=$(adb logcat -d *:E | grep -c "FATAL EXCEPTION")
if [ "$CRASHES" -gt 0 ]; then
    echo "❌ App crashed on startup!"
    adb logcat -d *:E | grep -A 10 "FATAL EXCEPTION"
else
    echo "✅ App launched successfully"
    adb exec-out screencap -p > launch_success.png
fi
```

### Test Rotation Handling

```bash
# Capture portrait state
adb exec-out screencap -p > portrait.png

# Rotate to landscape
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 1
sleep 2

# Capture landscape state
adb exec-out screencap -p > landscape.png

# Check for crashes
adb logcat -d *:E | grep -c "FATAL EXCEPTION"

# Rotate back
adb shell settings put system user_rotation 0
```

### Test Offline Mode

```bash
# Disable network
adb shell svc wifi disable
adb shell svc data disable
sleep 2

# Trigger refresh action
adb shell input swipe 540 400 540 1200 300  # Pull to refresh
sleep 3

# Verify offline UI
adb exec-out screencap -p > offline_state.png
adb exec-out uiautomator dump /dev/tty | grep -i "offline\|no connection\|error"

# Re-enable network
adb shell svc wifi enable
adb shell svc data enable
```

### Test Deep Link

```bash
adb shell am start -a android.intent.action.VIEW -d "myapp://item/123" nl.package.app
sleep 2
adb exec-out screencap -p > deeplink_result.png
```

## Device Management

### Multiple Devices

```bash
# List all connected
adb devices

# Target specific device
adb -s emulator-5554 shell screencap /sdcard/screen.png
adb -s emulator-5556 install app.apk
```

### Device Properties

```bash
# Android version
adb shell getprop ro.build.version.release

# API level
adb shell getprop ro.build.version.sdk

# Device model
adb shell getprop ro.product.model

# Screen resolution
adb shell wm size

# Screen density
adb shell wm density
```

### Change Device Settings

```bash
# Set locale (for Dutch testing)
adb shell am broadcast -a com.android.intent.action.SET_LOCALE --es com.android.intent.extra.LOCALE "nl_NL"

# Set font scale (accessibility testing)
adb shell settings put system font_scale 2.0

# Toggle dark mode
adb shell cmd uimode night yes    # Dark mode on
adb shell cmd uimode night no     # Dark mode off

# Set screen size (test smaller screens)
adb shell wm size 720x1280
adb shell wm size reset  # Restore original
```

## Optional: MCP Server for Advanced Use

For vision-based autonomous testing (Claude analyzes screenshots to decide next actions), consider adding the `android-adb-testing` MCP server:

```json
// .mcp.json in project root
{
  "mcpServers": {
    "android-adb-testing": {
      "command": "npx",
      "args": ["-y", "android-adb-testing"],
      "env": {
        "ANDROID_HOME": "${ANDROID_HOME}"
      }
    }
  }
}
```

Or `claude-in-mobile` for broader device support:

```bash
claude mcp add --transport stdio mobile -- npx -y claude-in-mobile
```

These MCP servers provide structured tool calls (screenshot, tap-by-text, element-find) instead of raw ADB commands, which can be more reliable for complex UI flows.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `adb: command not found` | Add `$ANDROID_HOME/platform-tools` to PATH |
| `error: no devices/emulators found` | Start emulator first, or check `adb devices` |
| `error: more than one device` | Use `adb -s emulator-5554` to target specific device |
| Emulator hangs on boot | Use `-no-snapshot-load` for cold boot |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | `adb uninstall nl.package.app` then reinstall |
| Screenshots are black | App uses `FLAG_SECURE` — remove for debug builds |
| `uiautomator dump` fails | Wait a moment after navigation, UI may still be animating |
| Slow emulator | Enable hardware acceleration: HAXM (Intel) or Hyper-V (AMD) |
