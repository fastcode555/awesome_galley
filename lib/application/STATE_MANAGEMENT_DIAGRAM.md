# State Management Visual Diagrams

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter Application                          │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                      MaterialApp                                │ │
│  │                                                                  │ │
│  │  ┌────────────────────────────────────────────────────────────┐│ │
│  │  │                    MultiProvider                            ││ │
│  │  │                                                              ││ │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    ││ │
│  │  │  │ ModeManager  │  │   Gallery    │  │    Image     │    ││ │
│  │  │  │              │  │  Controller  │  │  Controller  │    ││ │
│  │  │  │ChangeNotifier│  │ChangeNotifier│  │   Service    │    ││ │
│  │  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    ││ │
│  │  │         │                  │                  │             ││ │
│  │  └─────────┼──────────────────┼──────────────────┼─────────────┘│ │
│  │            │                  │                  │              │ │
│  │  ┌─────────▼──────────────────▼──────────────────▼─────────────┐│ │
│  │  │                      App Widgets                             ││ │
│  │  │                                                               ││ │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     ││ │
│  │  │  │   AppHome    │  │  Waterfall   │  │SingleImage   │     ││ │
│  │  │  │              │  │    View      │  │   Viewer     │     ││ │
│  │  │  │  Consumer    │  │  Consumer    │  │context.read()│     ││ │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘     ││ │
│  │  └───────────────────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Provider Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                      App Initialization                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AppInitializer                              │
│                                                                   │
│  Creates and initializes:                                        │
│  • SharedPreferences                                             │
│  • StateRepository                                               │
│  • CacheManager                                                  │
│  • FileSystemService                                             │
│  • ImageRepository                                               │
│  • ModeManager                                                   │
│  • CrashRecoveryManager                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MultiProvider Setup                         │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ChangeNotifierProvider<ModeManager>                      │   │
│  │   ↓ provides                                             │   │
│  │   • currentMode: BrowseMode                              │   │
│  │   • associatedFilePath: String?                          │   │
│  │   • initializeMode(args)                                 │   │
│  │   • switchToSystemBrowse()                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ChangeNotifierProvider<GalleryController>                │   │
│  │   ↓ provides                                             │   │
│  │   • images: List<ImageItem>                              │   │
│  │   • isLoading: bool                                      │   │
│  │   • errorMessage: String?                                │   │
│  │   • hasMoreImages: bool                                  │   │
│  │   • loadSystemImages()                                   │   │
│  │   • loadFolderImages(path)                               │   │
│  │   • loadMoreImages()                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Provider<ImageController>                                │   │
│  │   ↓ provides                                             │   │
│  │   • state: ImageLoadingState                             │   │
│  │   • errorMessage: String?                                │   │
│  │   • loadThumbnail(item)                                  │   │
│  │   • loadFullImage(item)                                  │   │
│  │   • loadMetadata(item)                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## State Flow: System Browse Mode

```
┌──────────────┐
│ User launches│
│     app      │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ AppInitializer.initialize()                              │
│ • Detects no launch arguments                            │
│ • ModeManager.initializeMode([])                         │
│ • Sets mode to BrowseMode.systemBrowse                   │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ AppHome.initState()                                      │
│ • Reads ModeManager                                      │
│ • Calls GalleryController.loadSystemImages()            │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ GalleryController.loadSystemImages()                     │
│ 1. Sets isLoading = true                                 │
│ 2. Calls notifyListeners()                               │
│ 3. Scans system directories via ImageRepository          │
│ 4. Loads first page (50 images)                          │
│ 5. Sets isLoading = false                                │
│ 6. Calls notifyListeners()                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Consumer<GalleryController> in WaterfallView            │
│ • Receives notification                                  │
│ • Rebuilds with new image list                           │
│ • Displays images in waterfall layout                    │
└──────────────────────────────────────────────────────────┘
```

## State Flow: File Association Mode

```
┌──────────────┐
│ User opens   │
│ image file   │
│ via OS       │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ AppInitializer.initialize()                              │
│ • Detects launch argument: /path/to/image.jpg            │
│ • ModeManager.initializeMode(['/path/to/image.jpg'])    │
│ • Sets mode to BrowseMode.fileAssociation                │
│ • Sets associatedFilePath = '/path/to/image.jpg'         │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ AppHome.initState()                                      │
│ • Reads ModeManager                                      │
│ • Extracts folder path from file path                    │
│ • Calls GalleryController.loadFolderImages(folder)      │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ GalleryController.loadFolderImages(folder)               │
│ 1. Sets isLoading = true                                 │
│ 2. Calls notifyListeners()                               │
│ 3. Scans folder via ImageRepository                      │
│ 4. Loads all images in folder                            │
│ 5. Sets isLoading = false                                │
│ 6. Calls notifyListeners()                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Consumer<ModeManager> in AppHome                         │
│ • Detects fileAssociation mode                           │
│ • Renders SingleImageViewer instead of WaterfallView    │
│ • Finds index of associated file in image list           │
│ • Opens viewer at that index                             │
└──────────────────────────────────────────────────────────┘
```

## State Flow: Image Loading

```
┌──────────────┐
│ User taps    │
│ image in     │
│ waterfall    │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ WaterfallView.onImageTap()                               │
│ • Navigates to SingleImageViewer                         │
│ • Passes image list and initial index                    │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ SingleImageViewer builds                                 │
│ • Creates PageView with images                           │
│ • For each page, creates _FullResolutionImage widget     │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ _FullResolutionImage.initState()                         │
│ • Calls _loadImage()                                     │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ _loadImage()                                             │
│ 1. Sets local state: isLoading = true                    │
│ 2. Gets ImageController via context.read()               │
│ 3. Calls imageController.loadFullImage(item)             │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ ImageController.loadFullImage(item)                      │
│ 1. Sets state = ImageLoadingState.loading                │
│ 2. Calls notifyListeners()                               │
│ 3. Generates cache key                                   │
│ 4. Checks cache (memory → disk)                          │
│ 5. If not cached, loads from file                        │
│ 6. Returns ImageData                                     │
│ 7. Sets state = ImageLoadingState.success                │
│ 8. Calls notifyListeners()                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ _loadImage() receives ImageData                          │
│ • Sets local state: imageData = result                   │
│ • Sets local state: isLoading = false                    │
│ • Widget rebuilds with Image.memory(imageData.bytes)     │
└──────────────────────────────────────────────────────────┘
```

## State Flow: Pagination

```
┌──────────────┐
│ User scrolls │
│ to bottom    │
│ (80%)        │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ WaterfallView._onScroll()                                │
│ • Detects scroll position >= 80%                         │
│ • Checks: !controller.isLoading && hasMoreImages         │
│ • Calls controller.loadMoreImages()                      │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ GalleryController.loadMoreImages()                       │
│ 1. Sets isLoading = true                                 │
│ 2. Calls notifyListeners()                               │
│ 3. Increments currentPage                                │
│ 4. Loads next 50 images from allImages                   │
│ 5. Appends to images list                                │
│ 6. Updates hasMoreImages flag                            │
│ 7. Sets isLoading = false                                │
│ 8. Calls notifyListeners()                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Consumer<GalleryController> in WaterfallView            │
│ • Receives notification                                  │
│ • Rebuilds with expanded image list                      │
│ • Shows loading indicator at bottom while loading        │
│ • Displays new images when loaded                        │
└──────────────────────────────────────────────────────────┘
```

## State Flow: Mode Switching

```
┌──────────────┐
│ User clicks  │
│ "Browse All  │
│  Images"     │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Button.onPressed()                                       │
│ • Calls modeManager.switchToSystemBrowse()               │
│ • Calls galleryController.loadSystemImages()             │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ ModeManager.switchToSystemBrowse()                       │
│ 1. Sets currentMode = BrowseMode.systemBrowse            │
│ 2. Sets associatedFilePath = null                        │
│ 3. Calls notifyListeners()                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Consumer<ModeManager> in AppHome                         │
│ • Receives notification                                  │
│ • Detects mode change to systemBrowse                    │
│ • Rebuilds to show WaterfallView instead of viewer       │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ GalleryController.loadSystemImages()                     │
│ • Loads system images (see System Browse flow above)     │
└──────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
┌──────────────┐
│ Error occurs │
│ during load  │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Controller catches exception                             │
│ • In try-catch block                                     │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Controller._setError(message)                            │
│ 1. Sets errorMessage = message                           │
│ 2. Sets isLoading = false                                │
│ 3. Calls notifyListeners()                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Consumer in View                                         │
│ • Receives notification                                  │
│ • Checks if errorMessage != null                         │
│ • Displays error UI with message                         │
│ • Shows retry button                                     │
└──────┬───────────────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│ User clicks  │
│ retry button │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ Retry action                                             │
│ • Calls controller.loadSystemImages() again              │
│ • Clears error state                                     │
│ • Attempts operation again                               │
└──────────────────────────────────────────────────────────┘
```

## Performance Optimization: Selective Rebuilds

```
┌─────────────────────────────────────────────────────────┐
│                    Widget Tree                           │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Scaffold (doesn't rebuild)                         │ │
│  │                                                      │ │
│  │  ┌────────────────────────────────────────────────┐│ │
│  │  │ AppBar (doesn't rebuild)                       ││ │
│  │  │                                                  ││ │
│  │  │  ┌────────────────────────────────────────────┐││ │
│  │  │  │ Consumer<ModeManager>                      │││ │
│  │  │  │ (rebuilds only on mode change)             │││ │
│  │  │  │   Text: "System Mode" / "Folder Mode"      │││ │
│  │  │  └────────────────────────────────────────────┘││ │
│  │  └────────────────────────────────────────────────┘│ │
│  │                                                      │ │
│  │  ┌────────────────────────────────────────────────┐│ │
│  │  │ Consumer<GalleryController>                    ││ │
│  │  │ (rebuilds on image list change)                ││ │
│  │  │                                                  ││ │
│  │  │  ┌──────────────────────────────────────────┐ ││ │
│  │  │  │ WaterfallGrid                            │ ││ │
│  │  │  │                                            │ ││ │
│  │  │  │  ┌────────────────────────────────────┐  │ ││ │
│  │  │  │  │ RepaintBoundary                    │  │ ││ │
│  │  │  │  │ (prevents unnecessary repaints)    │  │ ││ │
│  │  │  │  │                                      │  │ ││ │
│  │  │  │  │  ImageTile (const constructor)     │  │ ││ │
│  │  │  │  └────────────────────────────────────┘  │ ││ │
│  │  │  └──────────────────────────────────────────┘ ││ │
│  │  └────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

Key Optimization Techniques:
1. Consumer only rebuilds its subtree
2. RepaintBoundary prevents repainting of unchanged widgets
3. const constructors for static widgets
4. Selective listening with Selector for specific properties
```

## Memory Management

```
┌─────────────────────────────────────────────────────────┐
│                  Controller Lifecycle                    │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │ 1. Creation                                        │ │
│  │    • MultiProvider creates controller              │ │
│  │    • Constructor initializes dependencies          │ │
│  └────────────────────────────────────────────────────┘ │
│                         ↓                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │ 2. Active Use                                      │ │
│  │    • Views listen via Consumer                     │ │
│  │    • State changes trigger notifyListeners()       │ │
│  │    • Listeners rebuild their widgets               │ │
│  └────────────────────────────────────────────────────┘ │
│                         ↓                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │ 3. Disposal                                        │ │
│  │    • App closes or provider removed                │ │
│  │    • dispose() called automatically                │ │
│  │    • Streams closed                                │ │
│  │    • Listeners removed                             │ │
│  │    • Resources freed                               │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

Example: GalleryController.dispose()
  1. _imageStreamController.close()
  2. super.dispose() (ChangeNotifier cleanup)
  3. All listeners automatically removed
  4. Memory freed by garbage collector
```

## Testing Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Unit Tests                            │
│                                                           │
│  Test controllers in isolation:                          │
│  • Mock dependencies (Repository, CacheManager)          │
│  • Verify state changes                                  │
│  • Verify notifyListeners() called                       │
│  • Test error handling                                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                  Widget Tests                            │
│                                                           │
│  Test views with mock providers:                         │
│  • Wrap widget with test provider                        │
│  • Verify UI updates on state changes                    │
│  • Test user interactions                                │
│  • Verify error states displayed                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                Integration Tests                         │
│                                                           │
│  Test complete flows:                                    │
│  • Real providers with mock services                     │
│  • Test state flow from action to UI                     │
│  • Test navigation and mode switching                    │
│  • Test pagination and loading                           │
└─────────────────────────────────────────────────────────┘
```

---

These diagrams provide a visual understanding of how state management works in the Image Gallery Viewer application. Refer to STATE_MANAGEMENT_INTEGRATION.md for detailed documentation and STATE_MANAGEMENT_EXAMPLES.md for code examples.
