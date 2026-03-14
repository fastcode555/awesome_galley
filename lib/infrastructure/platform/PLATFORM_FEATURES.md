# Platform-Specific Features Implementation

This document describes the platform-specific features implemented for the Image Gallery Viewer application.

## Overview

The application supports six platforms with platform-specific features:
- **Desktop**: Windows, macOS, Linux (file associations)
- **Mobile**: iOS, Android (permissions)
- **Web**: Browser-based file selection

## Desktop Platforms

### Windows

**File Association Registration**:
- Uses Windows Registry to register file associations
- Supports: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.bmp`
- Native implementation in `windows/runner/platform_channel_handler.cpp`
- Creates ProgID: `ImageGalleryViewer.Image`
- Registers in `HKEY_CURRENT_USER\Software\Classes`

**Set as Default App**:
- Opens Windows Settings (ms-settings:defaultapps)
- User must manually select the app as default

**EXIF Extraction**:
- Uses Windows Property System API
- Extracts: date taken, camera make/model, GPS coordinates

### macOS

**File Association Registration**:
- Configured via `Info.plist` (CFBundleDocumentTypes)
- Runtime verification through method channel
- Supports same formats as Windows

**Set as Default App**:
- Opens System Preferences to relevant section
- User must manually set default app

**EXIF Extraction**:
- Uses native macOS APIs through method channel
- Same metadata as Windows

**Implementation Status**: Native code needs to be added to `macos/Runner/`

### Linux

**File Association Registration**:
- Creates `.desktop` file in `~/.local/share/applications/`
- Registers MIME types
- Updates desktop database using `update-desktop-database`

**Set as Default App**:
- Uses `xdg-mime` command to set default for each MIME type
- Command: `xdg-mime default image-gallery-viewer.desktop <mime-type>`

**EXIF Extraction**:
- Uses `exiftool` command-line tool if available
- Falls back to null if not installed

## Mobile Platforms

### iOS

**Permissions**:
- Photo Library Access (NSPhotoLibraryUsageDescription)
- Uses `permission_handler` package
- Guides user to Settings if permission denied

**File Opening**:
- Receives files through app delegate
- Supports share sheet integration
- URL scheme handling

**EXIF Extraction**:
- Uses native iOS APIs through method channel

**Implementation Status**: Native code needs to be added to `ios/Runner/`

### Android

**Permissions**:
- Android 13+ (API 33+): `READ_MEDIA_IMAGES`
- Older versions: `READ_EXTERNAL_STORAGE`
- Uses `permission_handler` package
- Guides user to Settings if permission denied

**File Opening**:
- Receives files through intent
- Supports ACTION_VIEW intent
- Configured in AndroidManifest.xml

**EXIF Extraction**:
- Uses Android ExifInterface through method channel

**Implementation Status**: Native code needs to be added to `android/app/src/main/kotlin/`

## Web Platform

**File Access**:
- Uses file picker dialog (replaces directory scanning)
- No file associations (not applicable in browsers)
- No permissions required for file picker

**Features**:
- File picker for single/multiple images
- Blob URLs for image display
- Storage API for cache management
- No EXIF extraction (requires additional JS library)

**Limitations**:
- Cannot scan system directories
- Cannot set as default app
- Limited file system access

## Permission Manager

The `PermissionManager` class provides a unified interface for requesting permissions:

```dart
final permissionManager = PermissionManager();

// Request permission
final granted = await permissionManager.requestImageAccessPermission();

if (!granted) {
  // Show error message
  final message = permissionManager.getPermissionDeniedMessage();
  showDialog(message);
}
```

## Platform Integration Factory

The factory creates the appropriate platform integration:

```dart
final platform = PlatformIntegrationFactory.create();

// Check capabilities
if (PlatformIntegrationFactory.supportsFileAssociations()) {
  await platform.registerFileAssociations();
}

if (PlatformIntegrationFactory.requiresPermissions()) {
  final permissionManager = PermissionManager();
  await permissionManager.requestImageAccessPermission();
}
```

## Configuration Requirements

### iOS (Info.plist)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Image Gallery Viewer needs access to your photo library to display and browse your images.</string>

<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key>
    <string>Image</string>
    <key>LSHandlerRank</key>
    <string>Alternate</string>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.jpeg</string>
      <string>public.png</string>
      <string>com.compuserve.gif</string>
      <string>org.webmproject.webp</string>
      <string>com.microsoft.bmp</string>
    </array>
  </dict>
</array>
```

### Android (AndroidManifest.xml)

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Intent filter for file associations -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="file" />
    <data android:scheme="content" />
    <data android:mimeType="image/jpeg" />
    <data android:mimeType="image/png" />
    <data android:mimeType="image/gif" />
    <data android:mimeType="image/webp" />
    <data android:mimeType="image/bmp" />
</intent-filter>
```

### macOS (Info.plist)

```xml
<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key>
    <string>Image</string>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSHandlerRank</key>
    <string>Alternate</string>
    <key>LSItemContentTypes</key>
    <array>
      <string>public.jpeg</string>
      <string>public.png</string>
      <string>com.compuserve.gif</string>
      <string>org.webmproject.webp</string>
      <string>com.microsoft.bmp</string>
    </array>
  </dict>
</array>
```

## Testing

Each platform implementation should be tested on the target platform:

1. **File Associations** (Desktop):
   - Right-click image file → "Open with" → Verify app appears
   - Set as default → Verify double-click opens app
   - Launch with file argument → Verify file opens

2. **Permissions** (Mobile):
   - First launch → Permission dialog appears
   - Grant permission → App can access images
   - Deny permission → Error message with settings link
   - Permanently deny → Settings link works

3. **Web**:
   - File picker opens on button click
   - Selected files display correctly
   - Multiple file selection works

## Future Enhancements

1. **macOS/iOS Native Code**: Implement method channel handlers
2. **Android Native Code**: Implement method channel handlers
3. **Web EXIF**: Add JavaScript library for EXIF extraction
4. **File System Access API**: Use for advanced web file operations
5. **Deep Linking**: Support custom URL schemes for file opening
