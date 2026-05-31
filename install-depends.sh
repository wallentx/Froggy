#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Default SDK path
SDKMANAGER="/opt/android-sdk/tools/bin/sdkmanager"

# Find sdkmanager if not at the default path
if [ ! -f "$SDKMANAGER" ]; then
    if [ -n "$ANDROID_HOME" ] && [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
        SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
    elif [ -n "$ANDROID_SDK_ROOT" ] && [ -f "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
        SDKMANAGER="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    else
        # Try to locate sdkmanager in the PATH
        if command -v sdkmanager >/dev/null 2>&1; then
            SDKMANAGER=$(command -v sdkmanager)
        else
            echo "Error: sdkmanager not found at $SDKMANAGER or in PATH."
            echo "Please set ANDROID_HOME or run this script from an environment where sdkmanager is available."
            exit 1
        fi
    fi
fi

echo "Using sdkmanager located at: $SDKMANAGER"

# Define dependencies to install
DEPENDENCIES=(
    "ndk;28.2.13676358"
    "build-tools;35.0.0"
    "platforms;android-36"
    "cmake;3.22.1"
)

# Check if target directory is writable, if not, prepend sudo
SDK_DIR=$(dirname "$(dirname "$(dirname "$(dirname "$SDKMANAGER")")")")
if [ ! -w "$SDK_DIR" ]; then
    echo "Directory $SDK_DIR is not writable by current user."
    echo "Elevating privileges to install components..."
    SUDO="sudo"
else
    SUDO=""
fi

# Run the installation
echo "Installing Android SDK dependencies..."
yes | $SUDO "$SDKMANAGER" "${DEPENDENCIES[@]}"

echo "All dependencies successfully installed!"
