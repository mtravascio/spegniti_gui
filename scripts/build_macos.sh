#!/bin/bash
set -e

echo "=== Building Spegniti GUI for macOS ==="

# Ensure dependencies
echo "Getting dependencies..."
flutter pub get

# Build for macOS (dmg)
echo ""
echo "=== Building for macOS (dmg) ==="
# Note: Cross-compilation for macOS from Linux is not supported
# This will only work if you run this script on macOS
fastforge package --platform=macos --targets=dmg

echo ""
echo "=== Build complete ==="
echo "Output in dist/ directory"
