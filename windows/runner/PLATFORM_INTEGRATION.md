# Windows Platform Integration

This document describes the native Windows implementation for the Image Gallery Viewer platform integration.

## Files

- **platform_channel_handler.h**: Header file defining the PlatformChannelHandler class
- **platform_channel_handler.cpp**: Implementation of platform-specific functionality
- **main.cpp**: Updated to register the platform channel handler
- **flutter_window.h/cpp**: Updated to expose the plugin registrar

## Features Implemented

### 1. File Association Registration

The Windows implementation uses the Windows Registry to register file associations. When `registerFileAssociations` is called from Dart:

1. Creates registry keys under `HKEY_CURRENT_USER\Software\Classes\`
2. Registers a ProgID (`ImageGalleryViewer.Image`)
3. Associates file extensions (.jpg, .jpeg, .png, .gif, .webp, .bmp) with the ProgID
4. Sets the command to open files with the application
5. Notifies the shell of association changes using `SHChangeNotify`

**Registry Structure:**
```
HKEY_CURRENT_USER\Software\Classes\
  .jpg -> ImageGalleryViewer.Image
  .png -> ImageGalleryViewer.Image
  ...
  ImageGalleryViewer.Image\
    (Default) = "Image Gallery Viewer"
    shell\
      open\
        command\
          (Default) = "C:\path\to\app.exe" "%1"
```

### 2. Set as Default App

On Windows 10 and later, applications cannot programmatically set themselves as default without user interaction. The implementation opens Windows Settings to the Default Apps page where users can manually set the default application.

### 3. EXIF Data Extraction

Uses the Windows Property System API to extract EXIF metadata:

- **Properties extracted:**
  - Date taken (PKEY_Photo_DateTaken)
  - Camera manufacturer (PKEY_Photo_CameraManufacturer)
  - Camera model (PKEY_Photo_CameraModel)
  - GPS latitude (PKEY_GPS_Latitude)
  - GPS longitude (PKEY_GPS_Longitude)

The implementation converts GPS coordinates from degrees/minutes/seconds to decimal degrees.

### 4. Launch Arguments

Parses command-line arguments from `Platform.executableArguments` to detect files opened via file association. Filters out Flutter-specific flags (starting with `--`) and returns only file paths with supported image extensions.

## Dependencies

The implementation uses standard Windows APIs:
- `windows.h` - Core Windows API
- `shlobj.h` - Shell API for registry notifications
- `propsys.h` - Property System for EXIF extraction
- `propkey.h` - Property keys for image metadata

Links against:
- `propsys.lib` - Property System library

## Building

The CMakeLists.txt has been updated to include `platform_channel_handler.cpp` in the build. No additional configuration is required.

## Error Handling

- Registry operations return error codes that are checked and reported
- EXIF extraction failures return null (non-critical)
- Invalid arguments return FlutterError with descriptive messages
- All exceptions are caught and converted to Flutter errors

## Testing

To test the file association:

1. Build and run the application
2. Call `registerFileAssociations()` from Dart
3. Right-click an image file in Windows Explorer
4. Select "Open with" → "Choose another app"
5. "Image Gallery Viewer" should appear in the list
6. Select it and check "Always use this app"

## Limitations

- File associations are registered per-user (HKEY_CURRENT_USER), not system-wide
- Setting as default app requires user interaction on Windows 10+
- EXIF extraction depends on Windows Property System support for the image format
- Some EXIF fields may not be available for all image types

## Future Enhancements

- Add support for more EXIF fields (aperture, ISO, exposure time)
- Implement system-wide registration (requires admin privileges)
- Add icon association for registered file types
- Support for custom file type descriptions
