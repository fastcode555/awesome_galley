# Platform Integration Module

This module provides platform-specific functionality for the Image Gallery Viewer application.

## Overview

The platform integration module handles:
- **File Association Registration**: Registering the app to handle image file types
- **Launch Arguments**: Detecting when the app is opened via file association
- **EXIF Data Extraction**: Reading metadata from image files
- **Default App Settings**: Setting the app as the default image viewer

## Architecture

The module uses an abstract interface (`PlatformIntegration`) with platform-specific implementations:

- `WindowsPlatformIntegration`: Windows implementation using MethodChannel and Registry
- `MacOSPlatformIntegration`: macOS implementation using Info.plist and NSApplication
- `LinuxPlatformIntegration`: Linux implementation using .desktop files and MIME types

## Usage

```dart
import 'package:awesome_galley/infrastructure/platform/platform.dart';

// Get the appropriate platform integration
final platformIntegration = PlatformIntegrationFactory.create();

if (platformIntegration != null) {
  // Register file associations
  await platformIntegration.registerFileAssociations();
  
  // Get launch arguments (file paths)
  final launchArgs = await platformIntegration.getLaunchArguments();
  
  // Extract EXIF data
  final exifData = await platformIntegration.extractExifData('/path/to/image.jpg');
}
```

## Platform Support

| Platform | File Association | Launch Args | EXIF Extraction |
|----------|-----------------|-------------|-----------------|
| Windows  | ✅ MethodChannel | ✅ CLI Args  | ✅ MethodChannel |
| macOS    | ✅ Info.plist    | ✅ NSApp     | ✅ MethodChannel |
| Linux    | ✅ .desktop      | ✅ CLI Args  | ✅ exiftool      |
| iOS      | ❌ N/A           | ❌ N/A       | ❌ N/A           |
| Android  | ❌ N/A           | ❌ N/A       | ❌ N/A           |
| Web      | ❌ N/A           | ❌ N/A       | ❌ N/A           |

## Native Code Requirements

### Windows
- Requires native Windows code to handle MethodChannel calls
- Registry operations for file association registration
- Location: `windows/runner/flutter_window.cpp`

### macOS
- Requires Info.plist configuration (CFBundleDocumentTypes)
- Native code to handle NSApplication file open events
- Location: `macos/Runner/Info.plist` and `macos/Runner/AppDelegate.swift`

### Linux
- Uses standard Linux tools (xdg-mime, update-desktop-database)
- Optional: exiftool for EXIF extraction
- Creates .desktop file in `~/.local/share/applications/`

## File Association Configuration

### Supported Image Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)
- BMP (.bmp)

### MIME Types
- image/jpeg
- image/png
- image/gif
- image/webp
- image/bmp

## Error Handling

All methods handle errors gracefully:
- File association failures are logged but don't crash the app
- EXIF extraction failures return null
- Unsupported platforms return null from the factory

## Testing

Platform integration can be tested using:
- Unit tests with mocked MethodChannel
- Integration tests on actual platforms
- Manual testing of file association behavior

## Future Enhancements

- [ ] Support for additional image formats (TIFF, RAW)
- [ ] More detailed EXIF parsing
- [ ] Platform-specific optimizations
- [ ] Better error reporting and user feedback
