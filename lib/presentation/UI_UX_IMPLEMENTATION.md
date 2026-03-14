# UI/UX Implementation Guide

## Overview

This document describes the UI/UX optimizations implemented for the Image Gallery Viewer application, covering theme system, animations, loading/error states, and responsive layout.

**Task Reference**: Task 24 - UI/UX 优化和主题

## Components

### 1. Theme System (Task 24.1) ✅

**Location**: `lib/presentation/theme/`

#### AppTheme (`app_theme.dart`)

Provides comprehensive theme definitions for both light and dark modes:

**Features**:
- Material 3 design system
- Consistent color schemes
- Typography scale (Display, Headline, Title, Body, Label)
- Component themes (AppBar, Card, Button, Input, etc.)
- Spacing constants (XS: 4px, S: 8px, M: 16px, L: 24px, XL: 32px)
- Border radius constants (S: 4px, M: 8px, L: 16px)

**Usage**:
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeMode,
  // ...
)
```

#### ThemeManager (`theme_manager.dart`)

Manages theme mode switching and persistence:

**Features**:
- Theme mode management (light, dark, system)
- Persistent theme preference using SharedPreferences
- ChangeNotifier for reactive updates
- Convenient toggle and setter methods

**Usage**:
```dart
// Initialize
final prefs = await SharedPreferences.getInstance();
final themeManager = ThemeManager(prefs);

// Use in app
ChangeNotifierProvider.value(
  value: themeManager,
  child: Consumer<ThemeManager>(
    builder: (context, manager, child) {
      return MaterialApp(
        themeMode: manager.themeMode,
        // ...
      );
    },
  ),
)

// Toggle theme
await themeManager.toggleTheme();

// Set specific mode
await themeManager.setDarkMode();
await themeManager.setLightMode();
await themeManager.setSystemMode();
```

### 2. Animations (Task 24.2) ✅

**Location**: `lib/presentation/animations/`

#### FadeInAnimation (`fade_in_animation.dart`)

Smooth fade-in effects for waterfall images:

**Features**:
- Configurable duration and delay
- Custom curve support
- Staggered animation for list items

**Usage**:
```dart
// Simple fade-in
FadeInAnimation(
  duration: Duration(milliseconds: 300),
  child: Image.network(url),
)

// Staggered fade-in for lists
StaggeredFadeIn(
  index: index,
  baseDelay: Duration(milliseconds: 100),
  staggerDelay: Duration(milliseconds: 50),
  child: ImageItem(),
)
```

#### Page Transitions (`page_transitions.dart`)

Custom page transitions for single image viewer:

**Features**:
- Fade + scale transition for image viewer
- Slide transitions for navigation
- Configurable direction and duration

**Usage**:
```dart
// Image viewer transition
Navigator.of(context).push(
  ImageViewerPageRoute(
    builder: (context) => SingleImageViewer(),
    transitionDuration: Duration(milliseconds: 300),
  ),
);

// Slide transition
Navigator.of(context).push(
  SlidePageRoute(
    builder: (context) => NextPage(),
    direction: AxisDirection.left,
  ),
);
```

#### Zoom Animations (`zoom_animations.dart`)

Smooth zoom and pan animations for image viewer:

**Features**:
- Animated zoom to specific scale
- Zoom to fit functionality
- Focal point zooming
- Matrix4 interpolation

**Usage**:
```dart
final zoomController = ZoomAnimationController(transformationController);

// Animate to specific scale
zoomController.animateToScale(
  targetScale: 2.0,
  vsync: this,
  focalPoint: Offset(100, 100),
);

// Zoom to fit
zoomController.animateToFit(vsync: this);

// Zoom in
zoomController.animateZoomIn(vsync: this);
```

### 3. Loading and Error UI (Task 24.3) ✅

**Location**: `lib/presentation/widgets/`

#### UnifiedLoadingIndicator (`unified_loading_indicator.dart`)

Standardized loading indicators:

**Features**:
- Three size variants (small, medium, large)
- Optional message display
- Shimmer loading effect for placeholders
- Theme-aware colors

**Usage**:
```dart
// Basic loading indicator
UnifiedLoadingIndicator(
  message: 'Loading images...',
  size: LoadingSize.large,
)

// Shimmer placeholder
ShimmerLoading(
  width: 200,
  height: 150,
  borderRadius: BorderRadius.circular(8),
)
```

#### ErrorDisplay (`error_display.dart`)

Unified error display with consistent styling:

**Features**:
- Multiple error types (general, fileNotFound, corrupted, timeout, permission, network)
- Factory constructors for common errors
- Retry functionality
- Compact variant for small spaces
- Empty state display

**Usage**:
```dart
// Full error display
ErrorDisplay(
  message: 'Failed to load images',
  details: 'Check your internet connection',
  onRetry: () => loadImages(),
  type: ErrorType.network,
)

// Factory constructors
ErrorDisplay.fileNotFound(onRetry: retry)
ErrorDisplay.corrupted(onRetry: retry)
ErrorDisplay.timeout(onRetry: retry)
ErrorDisplay.permission(onRetry: retry)

// Compact error for thumbnails
CompactErrorDisplay(
  type: ErrorType.corrupted,
  onRetry: retry,
  size: 48.0,
)

// Empty state
EmptyStateDisplay(
  message: 'No images found',
  description: 'Try adding some images to your Pictures folder',
  icon: Icons.photo_library_outlined,
  action: ElevatedButton(...),
)
```

**Error Types**:
- `general`: Generic errors (red error icon)
- `fileNotFound`: File not found (orange search icon)
- `corrupted`: Corrupted files (red broken image icon)
- `timeout`: Loading timeout (orange clock icon)
- `permission`: Permission denied (amber lock icon)
- `network`: Network errors (blue wifi icon)

### 4. Responsive Layout (Task 24.4) ✅

**Location**: `lib/presentation/utils/`

#### ResponsiveLayout (`responsive_layout.dart`)

Comprehensive responsive layout utilities:

**Features**:
- Device type detection (mobile, tablet, desktop)
- Breakpoints (mobile: <600px, tablet: 600-1024px, desktop: ≥1024px)
- Orientation detection
- Waterfall column calculation
- Responsive spacing, padding, font sizes, icon sizes
- Generic value getter for any type

**Breakpoints**:
```dart
static const double mobileBreakpoint = 600;
static const double tabletBreakpoint = 1024;
static const double desktopBreakpoint = 1440;
```

**Usage**:
```dart
// Device type detection
final deviceType = ResponsiveLayout.getDeviceType(context);
final isMobile = ResponsiveLayout.isMobile(context);
final isTablet = ResponsiveLayout.isTablet(context);
final isDesktop = ResponsiveLayout.isDesktop(context);

// Orientation
final isLandscape = ResponsiveLayout.isLandscape(context);
final isPortrait = ResponsiveLayout.isPortrait(context);

// Waterfall columns (Requirements 3.5, 3.6, 3.7, 3.8)
final columns = ResponsiveLayout.calculateWaterfallColumns(context);
// Mobile: 2 columns
// Tablet: 3 columns
// Desktop: 4-8 columns (based on width)

// Responsive spacing
final spacing = ResponsiveLayout.getSpacing(
  context,
  mobile: 8.0,
  tablet: 12.0,
  desktop: 16.0,
);

// Responsive padding
final padding = ResponsiveLayout.getPadding(
  context,
  mobile: EdgeInsets.all(8.0),
  tablet: EdgeInsets.all(12.0),
  desktop: EdgeInsets.all(16.0),
);

// Responsive font size
final fontSize = ResponsiveLayout.getFontSize(
  context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);

// Generic value getter
final value = ResponsiveLayout.getValue<int>(
  context,
  mobile: 2,
  tablet: 3,
  desktop: 4,
);
```

**Widgets**:
```dart
// Responsive builder
ResponsiveBuilder(
  builder: (context, deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return MobileLayout();
      case DeviceType.tablet:
        return TabletLayout();
      case DeviceType.desktop:
        return DesktopLayout();
    }
  },
)

// Responsive value
ResponsiveValue<int>(
  mobile: 2,
  tablet: 3,
  desktop: 4,
  builder: (context, columns) {
    return GridView.count(crossAxisCount: columns);
  },
)

// Orientation builder
OrientationBuilder(
  builder: (context, orientation) {
    return orientation == Orientation.portrait
        ? PortraitLayout()
        : LandscapeLayout();
  },
)

// Screen size info
final screenSize = ScreenSize.of(context);
print('Width: ${screenSize.width}');
print('Height: ${screenSize.height}');
print('Device: ${screenSize.deviceType}');
print('Orientation: ${screenSize.orientation}');
print('Is Mobile: ${screenSize.isMobile}');
```

## Integration Examples

### Complete Waterfall View with All Optimizations

```dart
class WaterfallView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GalleryController>(
        builder: (context, controller, child) {
          // Loading state
          if (controller.images.isEmpty && controller.isLoading) {
            return const UnifiedLoadingIndicator(
              message: 'Loading images...',
              size: LoadingSize.large,
            );
          }

          // Error state
          if (controller.errorMessage != null) {
            return ErrorDisplay(
              message: 'Failed to load images',
              details: controller.errorMessage,
              onRetry: () => controller.loadSystemImages(),
              type: ErrorType.general,
            );
          }

          // Empty state
          if (controller.images.isEmpty) {
            return EmptyStateDisplay(
              message: 'No images found',
              description: 'Try adding some images to your Pictures folder',
              icon: Icons.photo_library_outlined,
            );
          }

          // Responsive layout
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = ResponsiveLayout.calculateWaterfallColumns(context);
              final spacing = ResponsiveLayout.getSpacing(context);
              
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: ResponsiveLayout.getPadding(context),
                    sliver: WaterfallGrid(
                      images: controller.images,
                      columnCount: columns,
                      spacing: spacing,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
```

### Single Image Viewer with Animations

```dart
// Navigate with custom transition
Navigator.of(context).push(
  ImageViewerPageRoute(
    builder: (context) => SingleImageViewer(
      images: images,
      initialIndex: index,
    ),
  ),
);

// Inside viewer - zoom animation
final zoomController = ZoomAnimationController(transformationController);

GestureDetector(
  onDoubleTap: () {
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      zoomController.animateToFit(vsync: this);
    } else {
      zoomController.animateZoomIn(vsync: this);
    }
  },
  child: InteractiveViewer(...),
)
```

### Theme Switching

```dart
// In settings or app bar
Consumer<ThemeManager>(
  builder: (context, themeManager, child) {
    return IconButton(
      icon: Icon(
        themeManager.isDarkMode
            ? Icons.light_mode
            : Icons.dark_mode,
      ),
      onPressed: () => themeManager.toggleTheme(),
    );
  },
)
```

## Requirements Mapping

### Task 24.1 - Theme System ✅
- ✅ Light and dark theme definitions
- ✅ Theme switching functionality
- ✅ Persistent theme preference
- ✅ Consistent colors, fonts, spacing

### Task 24.2 - Animations ✅
- ✅ Waterfall image fade-in animation (Requirement 9.4)
- ✅ Single image viewer open/close animation
- ✅ Image swipe transition animation
- ✅ Zoom and pan smooth animations

### Task 24.3 - Loading/Error UI ✅
- ✅ Unified loading indicator style
- ✅ Friendly error messages (Requirements 10.1, 10.2, 10.3, 10.5)
- ✅ Retry buttons and operation guidance
- ✅ Empty state displays

### Task 24.4 - Responsive Layout ✅
- ✅ Mobile device adaptation (Requirement 3.6)
- ✅ Tablet device adaptation (Requirement 3.7)
- ✅ Desktop device adaptation (Requirement 3.8)
- ✅ Landscape and portrait support
- ✅ Touch and mouse interaction optimization

## Testing

### Manual Testing Checklist

**Theme System**:
- [ ] Light theme displays correctly
- [ ] Dark theme displays correctly
- [ ] Theme switching works smoothly
- [ ] Theme preference persists across app restarts
- [ ] All components respect theme colors

**Animations**:
- [ ] Waterfall images fade in smoothly
- [ ] Image viewer opens with fade+scale animation
- [ ] Image swipe transitions are smooth
- [ ] Zoom animations are fluid
- [ ] No animation jank or stuttering

**Loading/Error UI**:
- [ ] Loading indicators display correctly
- [ ] Error messages are clear and helpful
- [ ] Retry buttons work as expected
- [ ] Empty states display appropriately
- [ ] Compact errors work in thumbnails

**Responsive Layout**:
- [ ] Mobile: 2 columns in waterfall
- [ ] Tablet: 3 columns in waterfall
- [ ] Desktop: 4+ columns in waterfall
- [ ] Layout adapts to orientation changes
- [ ] Spacing adjusts for device type
- [ ] Touch targets are appropriate for device

### Widget Tests

```dart
testWidgets('ErrorDisplay shows retry button', (tester) async {
  var retryPressed = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: ErrorDisplay(
        message: 'Test error',
        onRetry: () => retryPressed = true,
      ),
    ),
  );
  
  expect(find.text('Test error'), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
  
  await tester.tap(find.text('Retry'));
  expect(retryPressed, isTrue);
});

testWidgets('ResponsiveLayout calculates correct columns', (tester) async {
  // Mobile
  expect(ResponsiveLayout.calculateWaterfallColumnsFromWidth(400), 2);
  
  // Tablet
  expect(ResponsiveLayout.calculateWaterfallColumnsFromWidth(800), 3);
  
  // Desktop
  expect(ResponsiveLayout.calculateWaterfallColumnsFromWidth(1200), 4);
});
```

## Performance Considerations

1. **Theme Switching**: Uses ChangeNotifier for efficient updates
2. **Animations**: Hardware-accelerated with RepaintBoundary
3. **Responsive Layout**: Calculations cached where possible
4. **Error Display**: Lightweight widgets with minimal rebuilds

## Future Enhancements

1. **Theme System**:
   - Custom color schemes
   - Font family selection
   - Accent color customization

2. **Animations**:
   - Hero animations for image transitions
   - Parallax effects in waterfall
   - Pull-to-refresh animation

3. **Loading/Error UI**:
   - Skeleton loading screens
   - Progress indicators for large operations
   - Toast notifications for quick feedback

4. **Responsive Layout**:
   - Adaptive navigation (bottom nav on mobile, side nav on desktop)
   - Responsive image quality (lower res on mobile)
   - Adaptive UI density

## Conclusion

All four subtasks of Task 24 have been successfully implemented:

1. ✅ **24.1 Theme System**: Complete with light/dark themes and persistence
2. ✅ **24.2 Animations**: Comprehensive animation system for all transitions
3. ✅ **24.3 Loading/Error UI**: Unified, friendly UI for all states
4. ✅ **24.4 Responsive Layout**: Full responsive support for all devices

The implementation provides a polished, professional user experience across all platforms and device types.
