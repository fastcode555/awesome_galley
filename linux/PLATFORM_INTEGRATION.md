# Linux Platform Integration

This document describes the Linux implementation for the Image Gallery Viewer platform integration.

## Overview

Unlike Windows and macOS, the Linux implementation is entirely written in Dart and does not require native C++ code. It uses standard Linux desktop integration mechanisms through command-line tools and file system operations.

## Implementation

The implementation is located in:
- `lib/infrastructure/platform/linux_platform_integration.dart`

## Features Implemented

### 1. File Association Registration

File associations on Linux are registered using the XDG (X Desktop Group) standards:

**Components:**
1. **.desktop file** - Application descriptor
2. **MIME type registration** - Associates file types with the application
3. **Desktop database update** - Refreshes the system's application cache

**Process:**

1. Creates a .desktop file at `~/.local/share/applications/image-gallery-viewer.desktop`
2. The .desktop file includes:
   - Application name and description
   - Executable path
   - Supported MIME types
   - File type associations

3. Updates the desktop database using `update-desktop-database`

**.desktop File Format:**
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Image Gallery Viewer
Comment=View and browse images
Exec=/path/to/executable %f
Icon=image-viewer
Terminal=false
Categories=Graphics;Viewer;
MimeType=image/jpeg;image/png;image/gif;image/webp;image/bmp;
```

### 2. MIME Type Mapping

The implementation maps file extensions to MIME types:

| Extension | MIME Type |
|-----------|-----------|
| .jpg, .jpeg | image/jpeg |
| .png | image/png |
| .gif | image/gif |
| .webp | image/webp |
| .bmp | image/bmp |

### 3. Set as Default App

Uses the `xdg-mime` command-line tool to set the application as default for each MIME type:

```bash
xdg-mime default image-gallery-viewer.desktop image/jpeg
xdg-mime default image-gallery-viewer.desktop image/png
# ... for each MIME type
```

This updates the user's MIME associations in `~/.config/mimeapps.list`.

### 4. Launch Arguments

Parses command-line arguments from `Platform.executableArguments` to detect files opened via file association. Filters out Flutter-specific flags (starting with `--`) and returns only file paths with supported image extensions.

### 5. EXIF Data Extraction

Attempts to use the `exiftool` command-line utility if available:

```bash
exiftool -json /path/to/image.jpg
```

If `exiftool` is not installed, the method returns null (EXIF extraction is non-critical).

## Dependencies

### System Tools (Optional)

- **xdg-mime** - For setting default applications (usually pre-installed)
- **update-desktop-database** - For updating application cache (usually pre-installed)
- **exiftool** - For EXIF extraction (optional, install via package manager)

### Dart Packages

- `dart:io` - File system and process operations
- `package:path` - Path manipulation

## Installation

No additional installation steps are required. The implementation automatically:

1. Creates necessary directories if they don't exist
2. Generates the .desktop file at runtime
3. Registers MIME types and updates the database

## Error Handling

- Directory creation failures are reported as exceptions
- Missing command-line tools are handled gracefully (warnings in debug mode)
- EXIF extraction failures return null (non-critical)
- File system permission errors are caught and reported

## Testing

To test the file association:

1. Build and run the application
2. Call `registerFileAssociations()` from Dart
3. Right-click an image file in your file manager
4. Select "Open With" → "Image Gallery Viewer"
5. The application should appear in the list

To set as default:

1. Call `setAsDefaultApp()` from Dart
2. Right-click an image file
3. "Image Gallery Viewer" should now be the default application

## File Locations

- **.desktop file**: `~/.local/share/applications/image-gallery-viewer.desktop`
- **MIME associations**: `~/.config/mimeapps.list`
- **Desktop database**: `~/.local/share/applications/mimeinfo.cache`

## Compatibility

The implementation follows XDG standards and should work on:

- **Desktop Environments**: GNOME, KDE, XFCE, LXDE, Cinnamon, MATE, etc.
- **Distributions**: Ubuntu, Fedora, Debian, Arch, openSUSE, etc.
- **Display Servers**: X11 and Wayland

## Limitations

- File associations are per-user, not system-wide
- Requires XDG-compliant desktop environment
- EXIF extraction requires `exiftool` to be installed
- Icon association uses generic "image-viewer" icon
- Some desktop environments may cache associations differently

## Installing exiftool

For EXIF extraction support, install exiftool:

**Ubuntu/Debian:**
```bash
sudo apt-get install libimage-exiftool-perl
```

**Fedora:**
```bash
sudo dnf install perl-Image-ExifTool
```

**Arch Linux:**
```bash
sudo pacman -S perl-image-exiftool
```

## Future Enhancements

- Add custom application icon
- Implement native EXIF extraction (without exiftool dependency)
- Add support for system-wide registration (requires root)
- Implement D-Bus integration for better desktop integration
- Add support for thumbnail generation using freedesktop.org standards
- Support for additional MIME types and file formats

## Troubleshooting

### File associations not working

1. Check if .desktop file was created:
   ```bash
   ls -la ~/.local/share/applications/image-gallery-viewer.desktop
   ```

2. Verify MIME associations:
   ```bash
   xdg-mime query default image/jpeg
   ```

3. Update desktop database manually:
   ```bash
   update-desktop-database ~/.local/share/applications
   ```

### EXIF extraction not working

1. Check if exiftool is installed:
   ```bash
   which exiftool
   ```

2. Test exiftool manually:
   ```bash
   exiftool -json /path/to/image.jpg
   ```

### Permissions issues

Ensure the application has write permissions to:
- `~/.local/share/applications/`
- `~/.config/`

## References

- [XDG Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
- [XDG MIME Applications Specification](https://specifications.freedesktop.org/mime-apps-spec/latest/)
- [ExifTool Documentation](https://exiftool.org/)
