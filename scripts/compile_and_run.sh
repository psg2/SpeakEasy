#!/bin/bash
set -e

# Inspired by https://github.com/steipete/CodexBar/blob/main/Scripts/compile_and_run.sh

APP_NAME="SpeakEasy"

# 1. Kill the running application
echo "Stopping $APP_NAME..."
pkill -x "$APP_NAME" || true

# 2. Build the application
echo "Building..."
if command -v mise &> /dev/null; then
    mise run build
else
    echo "mise not found, running xcodebuild..."
    xcodebuild -project SpeakEasy.xcodeproj -scheme SpeakEasy -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
fi

# 3. Find the built application path dynamically
echo "Locating build..."
TARGET_BUILD_DIR=$(xcodebuild -project SpeakEasy.xcodeproj -scheme SpeakEasy -configuration Debug -showBuildSettings 2>/dev/null | grep -m 1 "TARGET_BUILD_DIR =" | cut -d "=" -f 2 | xargs)

if [ -z "$TARGET_BUILD_DIR" ]; then
    echo "Error: Could not find TARGET_BUILD_DIR."
    exit 1
fi

APP_PATH="$TARGET_BUILD_DIR/$APP_NAME.app"

# 4. Open the application
if [ -d "$APP_PATH" ]; then
    echo "Opening $APP_PATH..."
    open "$APP_PATH"
else
    echo "Error: App not found at $APP_PATH"
    exit 1
fi
