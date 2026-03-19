#!/bin/bash
set -e

echo "=== Building Spegniti GUI - All Platforms ==="

# Ensure dependencies
echo "Getting dependencies..."
flutter pub get

# Linux builds
echo ""
echo "=== Building for Linux (deb, appimage, zip) ==="
fastforge release --name linux

echo ""
echo "=== Build complete ==="
echo "Output in dist/ directory"
