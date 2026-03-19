#!/bin/bash
set -e

echo "=== Building Spegniti GUI for Linux ==="

# Ensure dependencies
echo "Getting dependencies..."
flutter pub get

# Build for Linux (deb, appimage, zip)
echo ""
echo "=== Building for Linux (deb, appimage, zip) ==="
fastforge package --platform=linux --targets=deb,appimage,zip

echo ""
echo "=== Build complete ==="
echo "Output in dist/ directory"
