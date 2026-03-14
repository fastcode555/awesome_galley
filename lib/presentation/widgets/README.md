# Presentation Widgets

This directory contains reusable UI widgets for the Image Gallery Viewer application.

## FolderPreview Widget

The `FolderPreview` widget displays a horizontal scrolling list of thumbnail images from the current folder, allowing users to quickly navigate between images.

### Features

- **Horizontal Scrolling**: Displays thumbnails in a horizontal scrollable list
- **Current Image Highlighting**: Highlights the currently viewed image with a blue border
- **Auto-scroll**: Automatically scrolls to show the current image when it changes
- **Tap to Select**: Users can tap any thumbnail to switch to that image
- **Error Handling**: Shows a broken image icon if a thumbnail fails to load

### Usage

```dart
import 'package:flutter/material.dart';
import 'package:awesome_galley/presentation/widgets/folder_preview.dart';
import 'package:awesome_galley/domain/models/image_item.dart';

class MyImageViewer extends StatefulWidget {
  @override
  State<MyImageViewer> createState() => _MyImageViewerState();
}

class _MyImageViewerState extends State<MyImageViewer> {
  late List<ImageItem> folderImages;
  late ImageItem currentImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main image display area
          Expanded(
            child: Center(
              child: Text('Current: ${currentImage.fileName}'),
            ),
          ),
          
          // Folder preview at the bottom
          FolderPreview(
            folderImages: folderImages,
            currentImage: currentImage,
            onImageSelect: (image) {
              setState(() {
                currentImage = image;
              });
            },
          ),
        ],
      ),
    );
  }
}
```

### Parameters

- `folderImages` (required): List of all images in the current folder
- `currentImage` (required): The currently viewed image (will be highlighted)
- `onImageSelect` (required): Callback function called when a thumbnail is tapped

### Implementation Details

#### Key Methods

1. **`_buildThumbnailList()`**
   - Creates a horizontal `ListView.builder` with all folder images
   - Each item is 100px wide with 4px horizontal margin
   - Uses `ScrollController` for programmatic scrolling

2. **`_highlightCurrentImage(bool isCurrentImage)`**
   - Returns blue color for the current image
   - Returns semi-transparent white for other images
   - Current image has a 3px border, others have 1px

3. **`_scrollToCurrentImage()`**
   - Calculates the scroll position to center the current image
   - Uses animated scrolling with 300ms duration
   - Clamps the position to valid scroll range
   - Called automatically when the current image changes

#### Layout Specifications

- **Container Height**: 120px
- **Background**: Black with 80% opacity
- **Thumbnail Size**: 100px width, auto height (maintains aspect ratio)
- **Thumbnail Margin**: 4px horizontal, 8px vertical padding for the list
- **Border Radius**: 8px for container, 6px for image clip
- **Current Image Border**: 3px blue border
- **Other Images Border**: 1px semi-transparent white border

### Requirements Validation

This widget validates the following requirements from the design document:

- **Requirement 7.1**: Opens when user clicks "Folder Preview" button
- **Requirement 7.2**: Loads all supported format images from current folder
- **Requirement 7.3**: Displays horizontal scrolling list of thumbnails
- **Requirement 7.4**: Highlights the currently viewed image
- **Requirement 7.5**: Switches to selected image when thumbnail is tapped
- **Requirement 7.6**: Images are sorted by filename (handled by parent component)
- **Requirement 7.7**: Supports up to 1000 images (handled by parent component)

### Example

See `folder_preview_example.dart` for a complete working example that demonstrates:
- Creating sample image data
- Managing current image state
- Handling image selection
- Displaying the widget in a full screen layout

### Notes

- The widget uses `Image.asset()` for loading thumbnails. In production, this should be replaced with a proper image loading mechanism that uses the `ImageController` and `CacheManager`.
- The widget assumes images are already sorted by filename. The parent component should handle sorting before passing the list.
- The widget handles up to 1000 images efficiently using `ListView.builder`, which only builds visible items.
