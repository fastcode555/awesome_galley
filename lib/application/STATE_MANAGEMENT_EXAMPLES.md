# State Management Integration Examples

This document provides practical examples of how to use the state management system in the Image Gallery Viewer application.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Loading Images](#loading-images)
3. [Handling User Interactions](#handling-user-interactions)
4. [Error Handling](#error-handling)
5. [Custom Widgets with State](#custom-widgets-with-state)
6. [Advanced Patterns](#advanced-patterns)

## Basic Usage

### Reading State Without Listening

Use `context.read<T>()` when you need to access a provider but don't need to rebuild when it changes:

```dart
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Read without listening - won't rebuild when controller changes
        final controller = context.read<GalleryController>();
        controller.loadSystemImages();
      },
      child: Text('Load Images'),
    );
  }
}
```

### Listening to State Changes

Use `Consumer<T>` when you need to rebuild based on state changes:

```dart
class ImageCounter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (context, controller, child) {
        // This rebuilds whenever controller.notifyListeners() is called
        return Text('Images: ${controller.images.length}');
      },
    );
  }
}
```

### Using context.watch()

Use `context.watch<T>()` when the entire widget needs to rebuild:

```dart
class ImageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This causes the entire widget to rebuild on changes
    final controller = context.watch<GalleryController>();
    
    return ListView.builder(
      itemCount: controller.images.length,
      itemBuilder: (context, index) {
        return ImageTile(image: controller.images[index]);
      },
    );
  }
}
```

## Loading Images

### Example 1: Load System Images on App Start

```dart
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load images after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryController>().loadSystemImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.images.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        
        return GridView.builder(
          itemCount: controller.images.length,
          itemBuilder: (context, index) {
            return ImageTile(image: controller.images[index]);
          },
        );
      },
    );
  }
}
```

### Example 2: Load Folder Images

```dart
class FolderButton extends StatelessWidget {
  final String folderPath;
  
  const FolderButton({required this.folderPath});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final controller = context.read<GalleryController>();
        
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        
        // Load folder images
        await controller.loadFolderImages(folderPath);
        
        // Close loading dialog
        Navigator.of(context).pop();
      },
      child: Text('Open Folder'),
    );
  }
}
```

### Example 3: Infinite Scroll with Pagination

```dart
class InfiniteScrollList extends StatefulWidget {
  @override
  State<InfiniteScrollList> createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<InfiniteScrollList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when scrolled to 80% of content
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      final controller = context.read<GalleryController>();
      
      // Only load if not already loading and more images available
      if (!controller.isLoading && controller.hasMoreImages) {
        controller.loadMoreImages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (context, controller, child) {
        return ListView.builder(
          controller: _scrollController,
          itemCount: controller.images.length + (controller.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end
            if (index == controller.images.length) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            return ImageTile(image: controller.images[index]);
          },
        );
      },
    );
  }
}
```

## Handling User Interactions

### Example 4: Image Tap to Open Viewer

```dart
class ImageGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (context, controller, child) {
        return GridView.builder(
          itemCount: controller.images.length,
          itemBuilder: (context, index) {
            final image = controller.images[index];
            
            return GestureDetector(
              onTap: () {
                // Navigate to single image viewer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SingleImageViewer(
                      images: controller.images,
                      initialIndex: index,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              },
              child: ImageTile(image: image),
            );
          },
        );
      },
    );
  }
}
```

### Example 5: Mode Switching

```dart
class ModeSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ModeManager>(
      builder: (context, modeManager, child) {
        return Row(
          children: [
            Text(
              modeManager.isFileAssociationMode() 
                ? 'Folder Mode' 
                : 'System Mode'
            ),
            SizedBox(width: 8),
            if (modeManager.isFileAssociationMode())
              ElevatedButton(
                onPressed: () {
                  // Switch to system browse mode
                  modeManager.switchToSystemBrowse();
                  
                  // Load system images
                  context.read<GalleryController>().loadSystemImages();
                },
                child: Text('Browse All Images'),
              ),
          ],
        );
      },
    );
  }
}
```

### Example 6: Loading Full Resolution Image

```dart
class FullImageDisplay extends StatefulWidget {
  final ImageItem item;
  
  const FullImageDisplay({required this.item});

  @override
  State<FullImageDisplay> createState() => _FullImageDisplayState();
}

class _FullImageDisplayState extends State<FullImageDisplay> {
  ImageData? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final imageController = context.read<ImageController>();
      final imageData = await imageController.loadFullImage(widget.item);
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImage,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return Image.memory(_imageData!.bytes);
  }
}
```

## Error Handling

### Example 7: Displaying Errors with Retry

```dart
class ImageListWithErrorHandling extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      builder: (context, controller, child) {
        // Show error state
        if (controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry loading
                    controller.loadSystemImages();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Show loading state
        if (controller.isLoading && controller.images.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        
        // Show empty state
        if (controller.images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No images found'),
              ],
            ),
          );
        }
        
        // Show images
        return ListView.builder(
          itemCount: controller.images.length,
          itemBuilder: (context, index) {
            return ImageTile(image: controller.images[index]);
          },
        );
      },
    );
  }
}
```

### Example 8: Timeout Handling

```dart
class ImageWithTimeout extends StatefulWidget {
  final ImageItem item;
  
  const ImageWithTimeout({required this.item});

  @override
  State<ImageWithTimeout> createState() => _ImageWithTimeoutState();
}

class _ImageWithTimeoutState extends State<ImageWithTimeout> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageData>(
      future: context.read<ImageController>().loadThumbnail(widget.item),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          final error = snapshot.error;
          
          // Check if it's a timeout error
          if (error is ImageLoadTimeoutException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_off, size: 48, color: Colors.orange),
                  SizedBox(height: 8),
                  Text('Loading timed out'),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}), // Retry
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Other errors
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 8),
                Text('Failed to load'),
              ],
            ),
          );
        }
        
        return Image.memory(snapshot.data!.bytes);
      },
    );
  }
}
```

## Custom Widgets with State

### Example 9: Reusable Image Tile with State

```dart
class StatefulImageTile extends StatefulWidget {
  final ImageItem item;
  final VoidCallback? onTap;
  
  const StatefulImageTile({
    required this.item,
    this.onTap,
  });

  @override
  State<StatefulImageTile> createState() => _StatefulImageTileState();
}

class _StatefulImageTileState extends State<StatefulImageTile> {
  ImageData? _thumbnail;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final imageController = context.read<ImageController>();
      final thumbnail = await imageController.loadThumbnail(widget.item);
      
      if (mounted) {
        setState(() {
          _thumbnail = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_hasError) {
      return Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        _thumbnail!.bytes,
        fit: BoxFit.cover,
      ),
    );
  }
}
```

### Example 10: Optimized Consumer with Child

```dart
class OptimizedImageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryController>(
      // The 'child' parameter is built once and reused
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'Image Gallery',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      builder: (context, controller, header) {
        return Column(
          children: [
            header!, // This doesn't rebuild when controller changes
            Expanded(
              child: ListView.builder(
                itemCount: controller.images.length,
                itemBuilder: (context, index) {
                  return ImageTile(image: controller.images[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

## Advanced Patterns

### Example 11: Multiple Providers

```dart
class ComplexWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to multiple providers
    return Consumer2<GalleryController, ModeManager>(
      builder: (context, galleryController, modeManager, child) {
        return Column(
          children: [
            Text('Mode: ${modeManager.currentMode}'),
            Text('Images: ${galleryController.images.length}'),
            if (galleryController.isLoading)
              CircularProgressIndicator(),
          ],
        );
      },
    );
  }
}
```

### Example 12: Selector for Optimized Rebuilds

```dart
class ImageCountDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Only rebuild when image count changes, not on other state changes
    return Selector<GalleryController, int>(
      selector: (context, controller) => controller.images.length,
      builder: (context, imageCount, child) {
        return Text('Total Images: $imageCount');
      },
    );
  }
}
```

### Example 13: ProxyProvider for Dependent Services

```dart
// In main.dart setup
MultiProvider(
  providers: [
    Provider<CacheManager>(create: (_) => CacheManager()),
    
    // ImageController depends on CacheManager
    ProxyProvider<CacheManager, ImageController>(
      update: (context, cacheManager, previous) {
        return ImageController(cacheManager: cacheManager);
      },
    ),
  ],
  child: MyApp(),
)
```

### Example 14: ChangeNotifierProxyProvider

```dart
// In main.dart setup
MultiProvider(
  providers: [
    ChangeNotifierProvider<ModeManager>(
      create: (_) => ModeManager(),
    ),
    
    // GalleryController depends on ModeManager
    ChangeNotifierProxyProvider<ModeManager, GalleryController>(
      create: (context) => GalleryController(
        repository: context.read<ImageRepository>(),
        cacheManager: context.read<CacheManager>(),
      ),
      update: (context, modeManager, previous) {
        // Update controller when mode changes
        if (previous != null) {
          previous.setMode(modeManager.currentMode);
        }
        return previous!;
      },
    ),
  ],
  child: MyApp(),
)
```

### Example 15: Testing with Provider

```dart
testWidgets('Image list displays correctly', (tester) async {
  // Create mock controller
  final mockController = MockGalleryController();
  when(mockController.images).thenReturn([testImage1, testImage2]);
  when(mockController.isLoading).thenReturn(false);
  when(mockController.errorMessage).thenReturn(null);

  // Wrap widget with provider
  await tester.pumpWidget(
    ChangeNotifierProvider<GalleryController>.value(
      value: mockController,
      child: MaterialApp(
        home: ImageListWidget(),
      ),
    ),
  );

  // Verify
  expect(find.byType(ImageTile), findsNWidgets(2));
});
```

## Best Practices Summary

1. **Use `context.read()` for actions**: When you just need to call a method
2. **Use `Consumer` for rebuilds**: When you need to rebuild based on state changes
3. **Use `Selector` for optimization**: When you only care about specific state properties
4. **Use `child` parameter**: To avoid rebuilding static widgets
5. **Handle all states**: Loading, success, error, and empty states
6. **Provide retry mechanisms**: For failed operations
7. **Show loading indicators**: During async operations
8. **Dispose properly**: Clean up controllers and listeners
9. **Test with mocks**: Use mock providers for unit testing
10. **Keep widgets small**: Break down complex widgets into smaller, focused components

## Common Pitfalls

### ❌ Don't: Use context.read() in build method for state that changes

```dart
// BAD - Won't rebuild when controller changes
Widget build(BuildContext context) {
  final controller = context.read<GalleryController>();
  return Text('Images: ${controller.images.length}');
}
```

### ✅ Do: Use Consumer or context.watch()

```dart
// GOOD - Rebuilds when controller changes
Widget build(BuildContext context) {
  final controller = context.watch<GalleryController>();
  return Text('Images: ${controller.images.length}');
}
```

### ❌ Don't: Create providers inside build method

```dart
// BAD - Creates new provider on every rebuild
Widget build(BuildContext context) {
  return Provider<ImageController>(
    create: (_) => ImageController(),
    child: MyWidget(),
  );
}
```

### ✅ Do: Create providers at app level or in StatefulWidget

```dart
// GOOD - Provider created once
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<ImageController>(
      create: (_) => ImageController(),
      child: MaterialApp(...),
    );
  }
}
```

### ❌ Don't: Forget to dispose

```dart
// BAD - Memory leak
class MyController extends ChangeNotifier {
  final StreamController _controller = StreamController();
  // Missing dispose!
}
```

### ✅ Do: Always dispose resources

```dart
// GOOD - Proper cleanup
class MyController extends ChangeNotifier {
  final StreamController _controller = StreamController();
  
  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
```
