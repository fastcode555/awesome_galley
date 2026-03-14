import 'package:flutter/material.dart';

/// Responsive layout utilities for adapting UI to different screen sizes
/// 
/// Provides breakpoints and helpers for:
/// - Device type detection (mobile, tablet, desktop)
/// - Orientation handling
/// - Column count calculation
/// - Spacing adjustments
/// 
/// Requirements: Task 24.4 - Responsive layout
class ResponsiveLayout {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceTypeFromWidth(width);
  }

  /// Get device type from width value
  static DeviceType getDeviceTypeFromWidth(double width) {
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Calculate waterfall column count based on screen width
  /// 
  /// Requirements: 3.5, 3.6, 3.7, 3.8
  /// - Mobile: 2 columns
  /// - Tablet: 3 columns
  /// - Desktop: 4+ columns (based on width)
  static int calculateWaterfallColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return calculateWaterfallColumnsFromWidth(width);
  }

  /// Calculate waterfall column count from width value
  static int calculateWaterfallColumnsFromWidth(double width) {
    if (width < mobileBreakpoint) {
      return 2; // Mobile
    } else if (width < tabletBreakpoint) {
      return 3; // Tablet
    } else {
      // Desktop: 1 column per 300px, minimum 4, maximum 8
      return (width / 300).floor().clamp(4, 8);
    }
  }

  /// Get responsive spacing based on device type
  static double getSpacing(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Get responsive padding based on device type
  static EdgeInsets getPadding(BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(8.0),
    EdgeInsets tablet = const EdgeInsets.all(12.0),
    EdgeInsets desktop = const EdgeInsets.all(16.0),
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Get responsive font size based on device type
  static double getFontSize(BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Get responsive icon size based on device type
  static double getIconSize(BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Get value based on device type
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Responsive builder widget
/// 
/// Builds different widgets based on device type
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveLayout.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Responsive value widget
/// 
/// Returns different values based on device type
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T tablet;
  final T desktop;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveLayout.getValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return builder(context, value);
  }
}

/// Orientation builder widget
/// 
/// Builds different widgets based on orientation
class OrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Orientation orientation) builder;

  const OrientationBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return builder(context, orientation);
  }
}

/// Screen size information
class ScreenSize {
  final double width;
  final double height;
  final DeviceType deviceType;
  final Orientation orientation;
  final double pixelRatio;

  ScreenSize({
    required this.width,
    required this.height,
    required this.deviceType,
    required this.orientation,
    required this.pixelRatio,
  });

  factory ScreenSize.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ScreenSize(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      deviceType: ResponsiveLayout.getDeviceType(context),
      orientation: mediaQuery.orientation,
      pixelRatio: mediaQuery.devicePixelRatio,
    );
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
}
