#!/bin/bash

# Script to automatically update Flutter version based on environment variables
# This script should be run before flutter build commands in CodeMagic

set -e

# Default values
DEFAULT_VERSION_NAME="1.0."+${PROJECT_BUILD_NUMBER}
DEFAULT_BUILD_NUMBER=${PROJECT_BUILD_NUMBER:-"1"}

# Get version name and build number from environment variables or use defaults
VERSION_NAME=${FLUTTER_BUILD_NAME:-$DEFAULT_VERSION_NAME}
BUILD_NUMBER=${FLUTTER_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}

# Path to pubspec.yaml (adjust if running from different directory)
PUBSPEC_PATH="flutter_app/pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC_PATH"
    exit 1
fi

# Update the version in pubspec.yaml
echo "Updating version to: $VERSION_NAME+$BUILD_NUMBER"

# Use sed to replace the version line
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version of sed
    sed -i '' "s/^version: .*/version: $VERSION_NAME+$BUILD_NUMBER/" "$PUBSPEC_PATH"
else
    # Linux version of sed
    sed -i "s/^version: .*/version: $VERSION_NAME+$BUILD_NUMBER/" "$PUBSPEC_PATH"
fi

echo "Version updated successfully in $PUBSPEC_PATH"
echo "Current version: $(grep '^version:' $PUBSPEC_PATH)"