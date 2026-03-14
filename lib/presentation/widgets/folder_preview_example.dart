import 'package:flutter/material.dart';
import '../../domain/models/image_item.dart';
import '../../domain/models/image_format.dart';
import 'folder_preview.dart';

/// Example usage of the FolderPreview widget
class FolderPreviewExample extends StatefulWidget {
  const FolderPreviewExample({super.key});

  @override
  State<FolderPreviewExample> createState() => _FolderPreviewExampleState();
}

class _FolderPreviewExampleState extends State<FolderPreviewExample> {
  late List<ImageItem> _folderImages;
  late ImageItem _currentImage;

  @override
  void initState() {
    super.initState();
    
    // Create sample images
    _folderImages = List.generate(
      20,
      (index) => ImageItem(
        id: 'image_$index',
        filePath: '/path/to/image_$index.jpg',
        fileName: 'image_$index.jpg',
        width: 1920,
        height: 1080,
        fileSize: 1024 * 1024,
        modifiedTime: DateTime.now().subtract(Duration(days: index)),
        format: ImageFormat.jpeg,
      ),
    );
    
    // Set the current image to the middle one
    _currentImage = _folderImages[10];
  }

  void _handleImageSelect(ImageItem image) {
    setState(() {
      _currentImage = image;
    });
    
    // Show a snackbar to indicate the selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${image.fileName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Preview Example'),
      ),
      body: Column(
        children: [
          // Main image display area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image,
                    size: 200,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current Image: ${_currentImage.fileName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'ID: ${_currentImage.id}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          // Folder preview at the bottom
          FolderPreview(
            folderImages: _folderImages,
            currentImage: _currentImage,
            onImageSelect: _handleImageSelect,
          ),
        ],
      ),
    );
  }
}
