# macOS Platform Integration

This document describes the native macOS implementation for the Image Gallery Viewer platform integration.

## Files

- **Info.plist**: Updated with CFBundleDocumentTypes for file association
- **AppDelegate.swift**: Implements MethodChannel handler and EXIF extraction

## Features Implemented

### 1. File Association Configuration

File associations on macOS are configured declaratively in Info.plist using `CFBundleDocumentTypes`. The configuration includes:

**Supported UTIs (Uniform Type Identifiers):**
- `public.jpeg` - JPEG images
- `public.png` - PNG images
- `com.compuserve.gif` - GIF images
- `org.webmproject.webp` - WebP images
- `com.microsoft.bmp` - BMP images

**File Extensions:**
- .jpg, .jpeg, .png, .gif, .webp, .bmp

**Handler Rank:**
- Set to "Alternate" to appear in "Open With" menu without being the default

**Role:**
- Set to "Viewer" indicating the app can view but not edit these files

### 2. File Open Handling

The AppDelegate implements NSApplication delegate methods to handle files opened via Finder:

- `application(_:openFile:)` - Called when a single file is opened
- `application(_:openFiles:)` - Called when multiple files are opened

Opened files are stored and returned to Dart via the `getOpenedFiles` method channel call.

### 3. Set as Default App

On macOS, setting default applications requires user interaction. The implementation opens System Preferences to the relevant section where users can manually set the default application for file types.

### 4. EXIF Data Extraction

Uses the ImageIO framework to extract EXIF metadata:

**Properties extracted:**
- Date taken (kCGImagePropertyExifDateTimeOriginal)
- Camera make (kCGImagePropertyTIFFMake)
- Camera model (kCGImagePropertyTIFFModel)
- Focal length (kCGImagePropertyExifFocalLength)
- Aperture (kCGImagePropertyExifFNumber)
- ISO (kCGImagePropertyExifISOSpeedRatings)
- Exposure time (kCGImagePropertyExifExposureTime)
- GPS coordinates (kCGImagePropertyGPSDictionary)

GPS coordinates are converted from unsigned values with direction references (N/S, E/W) to signed decimal degrees.

## Method Channel API

The implementation handles the following method calls:

### verifyFileAssociations
- **Purpose**: Verify that file associations are configured
- **Arguments**: None
- **Returns**: nil (success) or FlutterError
- **Note**: File associations are configured in Info.plist, so this is a no-op

### openDefaultAppSettings
- **Purpose**: Open System Preferences for setting default apps
- **Arguments**: None
- **Returns**: nil
- **Implementation**: Opens System Preferences using URL scheme

### getOpenedFiles
- **Purpose**: Get list of files opened via Finder
- **Arguments**: None
- **Returns**: Array of file paths (String[])
- **Note**: Clears the list after returning

### extractExifData
- **Purpose**: Extract EXIF metadata from an image file
- **Arguments**: `{ "filePath": String }`
- **Returns**: Dictionary of EXIF data or nil if no data available

## Dependencies

The implementation uses standard macOS frameworks:
- `Cocoa` - macOS UI framework
- `FlutterMacOS` - Flutter embedding for macOS
- `ImageIO` - Image metadata extraction

No additional dependencies or linking is required.

## Building

No changes to build configuration are required. The Info.plist changes are automatically included in the app bundle.

## Error Handling

- Method calls with invalid arguments return FlutterError
- EXIF extraction failures return nil (non-critical)
- File open events are queued and returned on next `getOpenedFiles` call
- Missing EXIF fields are omitted from the result dictionary

## Testing

To test the file association:

1. Build and run the application
2. Right-click an image file in Finder
3. Select "Open With" → "Image Gallery Viewer"
4. The application should launch and receive the file path

To set as default:

1. Right-click an image file in Finder
2. Select "Get Info"
3. Under "Open with:", select "Image Gallery Viewer"
4. Click "Change All..." to set for all files of this type

## Info.plist Configuration

The CFBundleDocumentTypes array in Info.plist defines the file associations:

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
    <key>CFBundleTypeExtensions</key>
    <array>
      <string>jpg</string>
      <string>jpeg</string>
      <string>png</string>
      <string>gif</string>
      <string>webp</string>
      <string>bmp</string>
    </array>
  </dict>
</array>
```

## Limitations

- Setting as default app requires user interaction (macOS security policy)
- File associations are configured at build time in Info.plist
- EXIF extraction depends on ImageIO framework support for the image format
- Some EXIF fields may not be available for all image types

## Future Enhancements

- Add support for more EXIF fields
- Implement custom file type icons
- Add support for Quick Look preview
- Implement drag-and-drop file handling
- Add support for opening files from command line
