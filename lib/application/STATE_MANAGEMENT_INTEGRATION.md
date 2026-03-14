# State Management Integration

## Overview

This document describes the state management integration for the Image Gallery Viewer application using the Provider package.

## Architecture

The application uses **Provider** for state management with a clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Waterfall    │  │ Single Image │  │ Folder       │  │
│  │ View         │  │ Viewer       │  │ Preview      │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │ Consumer         │ Consumer         │ Consumer │
└─────────┼──────────────────┼──────────────────┼─────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────┐
│         │    Provider      │                  │          │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  │
│  │ Gallery      │  │ Image        │  │ Mode         │  │
│  │ Controller   │  │ Controller   │  │ Manager      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                   Application Layer                      │
└─────────────────────────────────────────────────────────┘
```

## State Providers

### 1. ModeManager (ChangeNotifierProvider)

**Purpose**: Manages application browse mode (System Browse vs File Association)

**Lifecycle**: Created once at app initialization and persists throughout app lifetime

**State**:
- `currentMode`: Current browse mode (systemBrowse or fileAssociation)
- `associatedFilePath`: File path when opened via file association

**Usage**:
```dart
// Read mode
final modeManager = context.read<ModeManager>();
final mode = modeManager.currentMode;

// Listen to changes
Consumer<ModeManager>(
  builder: (context, modeManager, child) {
    return Text(modeManager.isFileAssociationMode() ? 'Folder' : 'System');
  },
)
```

### 2. GalleryController (ChangeNotifierProvider)

**Purpose**: Manages image collection loading and pagination

**Lifecycle**: Created once at app initialization

**State**:
- `images`: Current list of loaded images
- `isLoading`: Loading state flag
- `errorMessage`: Error message if loading failed
- `hasMoreImages`: Whether more images are available for pagination
- `currentMode`: Current browse mode
- `currentFolderPath`: Current folder path (if in folder mode)

**Usage**:
```dart
// Trigger actions
final controller = context.read<GalleryController>();
await controller.loadSystemImages();
await controller.loadFolderImages('/path/to/folder');
await controller.loadMoreImages();

// Listen to changes
Consumer<GalleryController>(
  builder: (context, controller, child) {
    if (controller.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView(children: controller.images.map(...).toList());
  },
)
```

### 3. ImageController (Provider)

**Purpose**: Manages individual image loading operations (thumbnails, full images, metadata)

**Lifecycle**: Created once at app initialization

**State**:
- `state`: Current loading state (idle, loading, success, error)
- `errorMessage`: Error message if loading failed

**Usage**:
```dart
// Load images
final imageController = context.read<ImageController>();
final thumbnail = await imageController.loadThumbnail(imageItem);
final fullImage = await imageController.loadFullImage(imageItem);
final metadata = await imageController.loadMetadata(imageItem);

// Check state
if (imageController.isLoading) {
  // Show loading indicator
}
```

## Provider Setup

The providers are configured in `main.dart` using `MultiProvider`:

```dart
MultiProvider(
  providers: [
    // ModeManager - manages browse mode
    ChangeNotifierProvider<ModeManager>.value(
      value: initializer.modeManager,
    ),
    
    // GalleryController - manages image collection
    ChangeNotifierProvider<GalleryController>(
      create: (_) => GalleryController(
        repository: initializer.imageRepository,
        cacheManager: initializer.cacheManager,
      ),
    ),
    
    // ImageController - manages individual image loading
    Provider<ImageController>(
      create: (_) => ImageController(
        cacheManager: initializer.cacheManager,
      ),
    ),
  ],
  child: MaterialApp(...),
)
```

## Reactive Updates

### Pattern 1: Consumer Widget

Use `Consumer` when you need to rebuild a widget tree based on state changes:

```dart
Consumer<GalleryController>(
  builder: (context, controller, child) {
    // This rebuilds when controller notifies listeners
    return ListView.builder(
      itemCount: controller.images.length,
      itemBuilder: (context, index) {
        return ImageTile(image: controller.images[index]);
      },
    );
  },
)
```

### Pattern 2: context.read()

Use `context.read()` when you only need to trigger actions without listening to changes:

```dart
void _loadImages() {
  final controller = context.read<GalleryController>();
  controller.loadSystemImages();
}
```

### Pattern 3: context.watch()

Use `context.watch()` when you need to rebuild the entire widget on state changes:

```dart
@override
Widget build(BuildContext context) {
  final controller = context.watch<GalleryController>();
  
  if (controller.isLoading) {
    return CircularProgressIndicator();
  }
  
  return ListView(...);
}
```

## State Flow Examples

### Example 1: Loading System Images

```
User Action: App launches
    ↓
AppHome.initState()
    ↓
context.read<GalleryController>().loadSystemImages()
    ↓
GalleryController.loadSystemImages()
    ↓
notifyListeners() called
    ↓
Consumer<GalleryController> rebuilds
    ↓
WaterfallView displays images
```

### Example 2: Opening Single Image

```
User Action: Tap image in waterfall
    ↓
onImageTap callback
    ↓
Navigator.push(SingleImageViewer)
    ↓
SingleImageViewer uses context.read<ImageController>()
    ↓
ImageController.loadFullImage()
    ↓
Image displayed in viewer
```

### Example 3: Mode Switching

```
User Action: Click "Switch to System Browse"
    ↓
context.read<ModeManager>().switchToSystemBrowse()
    ↓
ModeManager.switchToSystemBrowse()
    ↓
notifyListeners() called
    ↓
Consumer<ModeManager> rebuilds
    ↓
AppHome rebuilds with new mode
    ↓
WaterfallView displayed instead of SingleImageViewer
```

## Best Practices

### 1. Use the Right Provider Type

- **ChangeNotifierProvider**: For controllers that need to notify listeners (GalleryController, ModeManager)
- **Provider**: For services that don't change (ImageController)
- **StreamProvider**: For stream-based data (not used in this app)

### 2. Minimize Rebuilds

- Use `Consumer` with a specific type to only rebuild when that provider changes
- Use `child` parameter in `Consumer` to avoid rebuilding static widgets
- Use `RepaintBoundary` for expensive widgets

Example:
```dart
Consumer<GalleryController>(
  builder: (context, controller, child) {
    return Column(
      children: [
        Text('Images: ${controller.images.length}'),
        child!, // This doesn't rebuild
      ],
    );
  },
  child: ExpensiveStaticWidget(),
)
```

### 3. Avoid Memory Leaks

- Always dispose controllers in `dispose()` method
- Close streams and stream controllers
- Remove listeners when no longer needed

### 4. Error Handling

- Controllers should catch errors and update state
- UI should display error messages from controller state
- Provide retry mechanisms for failed operations

Example:
```dart
if (controller.errorMessage != null) {
  return ErrorWidget(
    message: controller.errorMessage!,
    onRetry: () => controller.loadSystemImages(),
  );
}
```

### 5. Loading States

- Always show loading indicators during async operations
- Disable actions while loading to prevent duplicate requests
- Use skeleton screens for better UX

Example:
```dart
if (controller.isLoading && controller.images.isEmpty) {
  return LoadingIndicator();
}

if (controller.isLoading) {
  // Show loading at bottom for pagination
  return Column(
    children: [
      ImageList(images: controller.images),
      LoadingIndicator(),
    ],
  );
}
```

## Testing State Management

### Unit Testing Controllers

```dart
test('GalleryController loads system images', () async {
  final mockRepository = MockImageRepository();
  final mockCacheManager = MockCacheManager();
  
  final controller = GalleryController(
    repository: mockRepository,
    cacheManager: mockCacheManager,
  );
  
  when(mockRepository.scanSystemDirectories())
      .thenAnswer((_) async => [testImage1, testImage2]);
  
  await controller.loadSystemImages();
  
  expect(controller.images.length, 2);
  expect(controller.isLoading, false);
});
```

### Widget Testing with Provider

```dart
testWidgets('WaterfallView displays images', (tester) async {
  final controller = GalleryController(
    repository: mockRepository,
    cacheManager: mockCacheManager,
  );
  
  await tester.pumpWidget(
    ChangeNotifierProvider<GalleryController>.value(
      value: controller,
      child: MaterialApp(
        home: WaterfallView(),
      ),
    ),
  );
  
  // Trigger load
  controller.loadSystemImages();
  await tester.pump();
  
  // Verify images displayed
  expect(find.byType(ImageTile), findsNWidgets(2));
});
```

## Performance Considerations

### 1. Lazy Loading

Images are loaded on-demand using `LazyImageLoader` widget:
- Only visible images are loaded
- Thumbnails are cached for fast access
- Full resolution images loaded only in SingleImageViewer

### 2. Pagination

GalleryController implements pagination:
- Loads 50 images per page
- Triggers next page at 80% scroll
- Prevents loading duplicate pages

### 3. Caching

Multi-level caching strategy:
- Memory cache (L1): 100 thumbnails
- Disk cache (L2): 500MB
- Automatic cache cleanup

### 4. Background Operations

- Thumbnail preloading in background
- Cache cleanup in background
- No blocking of UI thread

## Troubleshooting

### Issue: Widget not rebuilding

**Solution**: Ensure you're using `Consumer` or `context.watch()`, not `context.read()`

### Issue: "Provider not found" error

**Solution**: Ensure the widget is a descendant of the `MultiProvider` in the widget tree

### Issue: Memory leaks

**Solution**: Check that all controllers are properly disposed and streams are closed

### Issue: Duplicate loads

**Solution**: Check loading flags before triggering new loads

## Future Enhancements

Potential improvements to state management:

1. **Riverpod Migration**: Consider migrating to Riverpod for better testability and compile-time safety
2. **State Persistence**: Add automatic state saving/restoration using `RestorationMixin`
3. **Undo/Redo**: Implement command pattern for undo/redo functionality
4. **Optimistic Updates**: Update UI immediately before async operations complete
5. **State Machines**: Use explicit state machines for complex state transitions

## References

- [Provider Package Documentation](https://pub.dev/packages/provider)
- [Flutter State Management Guide](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [ChangeNotifier Best Practices](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)
