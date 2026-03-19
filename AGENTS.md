# AGENTS.md - Spegniti GUI

## Project Overview
Flutter desktop application for scheduling system shutdown. Uses GetX for state management and desktop_window for window control.

## Build Commands

### Flutter SDK
```bash
# Use Flutter from FVM (Flutter Version Management)
fvm flutter <command>

# Or standard flutter
flutter <command>
```

### Build
```bash
# Debug build (Linux)
flutter build linux --debug

# Release build (Linux)
flutter build linux --release

# Build for specific target
flutter build linux --release --target-platform <platform>
```

### Lint & Analyze
```bash
# Run static analysis
flutter analyze

# Run with verbose output
flutter analyze -v

# Analyze specific file/directory
flutter analyze lib/main.dart
```

### Test
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests with specific reporter
flutter test --reporter expanded
```

### Clean & Rebuild
```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

## Code Style Guidelines

### General
- Follows [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Uses `flutter_lints` package (included via `package:flutter_lints/flutter.yaml`)
- 2-space indentation for Dart code

### Imports
```dart
// Order: dart: > package: > relative:
// Separate each group with a blank line

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:desktop_window/desktop_window.dart';

import 'app/routes/app_pages.dart';
```

### Naming Conventions
- Classes: `PascalCase` (e.g., `ShutdownController`, `ShutdownTimerScreen`)
- Variables/functions: `camelCase` (e.g., `remainingTime`, `startTimer()`)
- Private members: `_leadingUnderscore` (e.g., `_timer`, `_shutdown()`)
- Constants: `kCamelCase` with `k` prefix (e.g., `kIsWeb`)
- Rx observables (GetX): `Rx<Type>` suffix (e.g., `Rx<int> remainingTime`)

### Widgets
- Use `const` constructors when possible
- Prefer `StatelessWidget` over `StatefulWidget` if no state management needed
- Use `GetMaterialApp` instead of `MaterialApp` when using GetX
- Place `Widget build()` method as the last method in the class

### State Management (GetX)
```dart
// Controller definition
class ShutdownController extends GetxController {
  Rx<int> remainingTime = 0.obs;
  Rx<bool> timerStarted = false.obs;
  
  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}

// Usage in widget
final controller = Get.put(ShutdownController());

// Reactive UI
Obx(() => Text('${controller.remainingTime.value}'));
```

### Error Handling
- Use try-catch for async operations
- Handle platform-specific exceptions
- Use `kIsWeb` check for web-incompatible code
- Provide meaningful error messages in debugPrint/logging

### Platform-Specific Code
```dart
import 'dart:io' show Platform;

if (Platform.isWindows) {
  // Windows-specific
} else if (Platform.isLinux) {
  // Linux-specific  
} else if (Platform.isMacOS) {
  // macOS-specific
}
```

### File Organization
```
lib/
  main.dart                 # App entry point
  app/
    controllers/           # GetX controllers
    views/                 # UI screens/widgets
    routes/                # Navigation routes
    bindings/              # GetX bindings
    services/              # Business logic services
test/
  widget_test.dart         # Widget tests
```

### Annotations & Ignore Comments
```dart
// ignore: avoid_print  # When necessary to suppress lint
// ignore_for_file: avoid_print  # For entire file
```

## Development Notes

### Dependencies
- `get: ^4.6.6` - State management and navigation
- `desktop_window: ^0.4.2` - Desktop window control
- `cupertino_icons: ^1.0.8` - iOS-style icons

### Dev Dependencies
- `flutter_lints: ^5.0.0` - Linting rules

### Flutter Version
Managed via FVM. Run `fvm flutter` commands instead of `flutter` when FVM is configured.

### Code Analysis
The project uses `package:flutter_lints/flutter.yaml` which includes:
- Effective Dart recommendations
- Flutter-specific best practices
- Common anti-patterns to avoid

## Common Tasks

### Add a new screen
1. Create widget in `lib/app/views/`
2. Add route in `lib/app/routes/`
3. Create binding if needed
4. Use `Get.to()` or `Get.toNamed()` for navigation

### Add a new controller
1. Create class extending `GetxController`
2. Implement `onClose()` for cleanup
3. Register with `Get.put()` or `Get.lazyPut()`

### Run in debug mode
```bash
flutter run -d linux
```
