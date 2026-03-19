#!/bin/bash
set -e

echo "=== Building Spegniti GUI for Windows ==="

# Ensure dependencies
echo "Getting dependencies..."
flutter pub get

# Build for Windows (exe)
echo ""
echo "=== Building for Windows (exe) ==="
# Note: Cross-compilation requires wine and inno setup on Linux
# This will only work if you have the required tools installed
fastforge package --platform=windows --targets=exe

echo ""
echo "=== Build complete ==="
echo "Output in dist/ directory"
