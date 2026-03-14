// Platform integration module for handling platform-specific functionality.
//
// This module provides abstractions for:
// - File association registration
// - Launch argument handling
// - EXIF metadata extraction
// - Platform-specific operations
// - Permission management (mobile)
// - Web file picking

export 'platform_integration.dart';
export 'platform_integration_factory.dart';
export 'windows_platform_integration.dart';
export 'macos_platform_integration.dart';
export 'linux_platform_integration.dart';
export 'ios_platform_integration.dart';
export 'android_platform_integration.dart';
export 'web_platform_integration.dart';
export 'permission_manager.dart';
export 'web_file_picker.dart';
