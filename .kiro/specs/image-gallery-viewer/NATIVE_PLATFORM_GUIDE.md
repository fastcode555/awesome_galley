# Native Platform Integration - Developer Guide

This guide provides a quick reference for developers working with the native platform code for the Image Gallery Viewer.

## Overview

The application uses platform-specific native code to handle:
- File association registration
- Default application settings
- EXIF metadata extraction
- Launch argument handling

## Architecture

```
Dart Layer (lib/infrastructure/platform/)
    ├── PlatformIntegration (interface)
    ├── WindowsPlatformIntegration (MethodChannel)
    ├── MacOSPlatformIntegration (MethodChannel)
    └── LinuxPlatformIntegration (Pure Dart)
           ↓
Native Layer
    ├── Windows (C++)
    │   └── platform_channel_handler.cpp
    ├── macOS (Swift)
    │   └── AppDelegate.swift
    └── Linux (Command-line tools)
```

## Platform-Specific Implementation

### Windows (C++)

**Location:** `windows/runner/`

**Key Files:**
- `platform_channel_handler.h/cpp` - MethodChannel handler
- `main.cpp` - Registration code

**Method Channel:** `image_gallery/platform`

**Methods:**
- `registerFileAssociations` - Register file types in Registry
- `setAsDefaultApp` - Open Windows Settings
- `extractExifData` - Extract EXIF using Property System

**Building:**
```bash
flutter build windows
```

**Testing:**
```bash
flutter run -d windows
```

### macOS (Swift)

**Location:** `macos/Runner/`

**Key Files:**
- `AppDelegate.swift` - MethodChannel handler and file open events
- `Info.plist` - File association configuration

**Method Channel:** `image_gallery/platform`

**Methods:**
- `verifyFileAssociations` - Verify Info.plist configuration
- `openDefaultAppSettings` - Open System Preferences
- `getOpenedFiles` - Get files opened via Finder
- `extractExifData` - Extract EXIF using ImageIO

**Building:**
```bash
flutter build macos
```

**Testing:**
```bash
flutter run -d macos
```

### Linux (Dart)

**Location:** `lib/infrastructure/platform/`

**Key File:**
- `linux_platform_integration.dart` - Pure Dart implementation

**Implementation:**
- Creates .desktop file at runtime
- Uses xdg-mime for default app setting
- Uses exiftool for EXIF extraction (optional)

**Building:**
```bash
flutter build linux
```

**Testing:**
```bash
flutter run -d linux
```

## Method Channel Protocol

### Channel Name
```
image_gallery/platform
```

### Methods

#### registerFileAssociations
**Arguments:**
```dart
{
  'extensions': ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'],
  'appName': 'Image Gallery Viewer',
  'appPath': '/path/to/executable'
}
```
**Returns:** `null` on success, `FlutterError` on failure

#### setAsDefaultApp
**Arguments:**
```dart
{
  'extensions': ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
}
```
**Returns:** `null` on success, `FlutterError` on failure

#### getOpenedFiles (macOS only)
**Arguments:** None
**Returns:** `List<String>` - Array of file paths

#### extractExifData
**Arguments:**
```dart
{
  'filePath': '/path/to/image.jpg'
}
```
**Returns:** `Map<String, dynamic>` or `null`

**EXIF Data Structure:**
```dart
{
  'dateTaken': '2024-01-15 14:30:00',
  'cameraMake': 'Canon',
  'cameraModel': 'EOS 5D Mark IV',
  'latitude': 37.7749,
  'longitude': -122.4194,
  'focalLength': 50.0,        // macOS only
  'aperture': 2.8,            // macOS only
  'iso': '400',               // macOS only
  'exposureTime': '1/250'     // macOS only
}
```

## Usage Example

```dart
import 'package:awesome_galley/infrastructure/platform/platform.dart';

// Get platform integration instance
final platformIntegration = PlatformIntegrationFactory.create();

if (platformIntegration != null) {
  // Register file associations
  try {
    await platformIntegration.registerFileAssociations();
    print('File associations registered successfully');
  } catch (e) {
    print('Failed to register file associations: $e');
  }
  
  // Get launch arguments (files opened via association)
  final launchArgs = await platformIntegration.getLaunchArguments();
  if (launchArgs.isNotEmpty) {
    print('Opened files: $launchArgs');
  }
  
  // Extract EXIF data
  final exifData = await platformIntegration.extractExifData('/path/to/image.jpg');
  if (exifData != null) {
    print('Date taken: ${exifData['dateTaken']}');
    print('Camera: ${exifData['cameraMake']} ${exifData['cameraModel']}');
    if (exifData.containsKey('latitude')) {
      print('Location: ${exifData['latitude']}, ${exifData['longitude']}');
    }
  }
  
  // Set as default app (opens system settings)
  await platformIntegration.setAsDefaultApp();
}
```

## Debugging

### Windows

**Enable Debug Output:**
Add to `windows/runner/main.cpp`:
```cpp
#define DEBUG_PLATFORM_CHANNEL
```

**Check Registry:**
```
regedit
Navigate to: HKEY_CURRENT_USER\Software\Classes\
Look for: .jpg, .png, ImageGalleryViewer.Image
```

**View Logs:**
Run from command line to see console output:
```bash
flutter run -d windows
```

### macOS

**Enable Debug Output:**
Debug output is automatically printed in debug builds.

**Check Info.plist:**
```bash
plutil -p macos/Runner/Info.plist | grep -A 20 CFBundleDocumentTypes
```

**View Logs:**
```bash
flutter run -d macos
# Or check Console.app for application logs
```

### Linux

**Enable Debug Output:**
Debug output is automatically printed in debug builds.

**Check .desktop File:**
```bash
cat ~/.local/share/applications/image-gallery-viewer.desktop
```

**Check MIME Associations:**
```bash
xdg-mime query default image/jpeg
cat ~/.config/mimeapps.list | grep image-gallery-viewer
```

**Test exiftool:**
```bash
exiftool -json /path/to/image.jpg
```

## Common Issues

### Windows

**Issue:** File associations not working
**Solution:** 
- Check if Registry keys were created
- Run `SHChangeNotify` to refresh shell
- Restart Windows Explorer

**Issue:** EXIF extraction returns null
**Solution:**
- Verify image file has EXIF data
- Check if Windows Property System supports the format
- Try with a different JPEG file

### macOS

**Issue:** Files not opening via Finder
**Solution:**
- Verify Info.plist has CFBundleDocumentTypes
- Rebuild the application
- Check Console.app for errors

**Issue:** getOpenedFiles returns empty array
**Solution:**
- Files are only queued when opened via Finder
- Call getOpenedFiles after application launch
- Check if NSApplication delegate methods are called

### Linux

**Issue:** .desktop file not created
**Solution:**
- Check write permissions to ~/.local/share/applications/
- Verify HOME environment variable is set
- Check debug output for errors

**Issue:** xdg-mime command fails
**Solution:**
- Verify xdg-mime is installed
- Check if desktop environment is XDG-compliant
- Try running command manually

## Performance Considerations

### Windows
- Registry operations are fast (< 10ms)
- EXIF extraction can be slow for large files (100-500ms)
- Consider caching EXIF data

### macOS
- ImageIO is highly optimized
- EXIF extraction is fast (10-50ms)
- File open events are queued efficiently

### Linux
- .desktop file creation is one-time operation
- exiftool can be slow (100-1000ms)
- Consider alternative EXIF libraries for better performance

## Security Considerations

### All Platforms
- File associations are per-user (not system-wide)
- No elevation/admin privileges required
- User must manually set default app (Windows 10+, macOS)

### Windows
- Registry operations use HKEY_CURRENT_USER (safe)
- No system-wide changes
- Follows Windows security best practices

### macOS
- Follows macOS sandboxing guidelines
- No private API usage
- App Store compatible

### Linux
- Follows XDG standards
- No root privileges required
- Compatible with all major desktop environments

## Testing Checklist

- [ ] Windows: File association registration works
- [ ] Windows: EXIF extraction returns correct data
- [ ] Windows: Launch arguments parsed correctly
- [ ] macOS: Info.plist configuration is valid
- [ ] macOS: Files open via Finder
- [ ] macOS: EXIF extraction returns comprehensive data
- [ ] Linux: .desktop file created successfully
- [ ] Linux: xdg-mime sets default app
- [ ] Linux: exiftool extracts EXIF data (if installed)
- [ ] All platforms: Error handling works correctly
- [ ] All platforms: No memory leaks
- [ ] All platforms: No crashes on invalid input

## Resources

### Windows
- [Windows Registry Documentation](https://docs.microsoft.com/en-us/windows/win32/sysinfo/registry)
- [Windows Property System](https://docs.microsoft.com/en-us/windows/win32/properties/windows-properties-system)
- [File Associations](https://docs.microsoft.com/en-us/windows/win32/shell/fa-file-types)

### macOS
- [CFBundleDocumentTypes](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundledocumenttypes)
- [ImageIO Framework](https://developer.apple.com/documentation/imageio)
- [NSApplication](https://developer.apple.com/documentation/appkit/nsapplication)

### Linux
- [XDG Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
- [XDG MIME Applications](https://specifications.freedesktop.org/mime-apps-spec/latest/)
- [ExifTool](https://exiftool.org/)

## Support

For issues or questions:
1. Check the platform-specific PLATFORM_INTEGRATION.md files
2. Review the completion report: TASK_7.2_COMPLETION.md
3. Check Flutter documentation for MethodChannel usage
4. Review platform-specific API documentation
