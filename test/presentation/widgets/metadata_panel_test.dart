import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/domain/models/image_metadata.dart';
import 'package:awesome_galley/domain/models/image_format.dart';
import 'package:awesome_galley/domain/models/exif_data.dart';
import 'package:awesome_galley/domain/models/gps_location.dart';
import 'package:awesome_galley/presentation/widgets/metadata_panel.dart';

void main() {
  group('MetadataPanel Widget Tests', () {
    late ImageMetadata basicMetadata;
    late ImageMetadata metadataWithExif;

    setUp(() {
      // Create basic metadata without EXIF
      basicMetadata = ImageMetadata(
        fileName: 'test_image.jpg',
        filePath: '/path/to/test_image.jpg',
        width: 1920,
        height: 1080,
        fileSize: 2457600, // 2.4 MB
        format: ImageFormat.jpeg,
        modifiedTime: DateTime(2024, 1, 15, 10, 30, 0),
      );

      // Create metadata with EXIF data
      metadataWithExif = ImageMetadata(
        fileName: 'photo_with_exif.jpg',
        filePath: '/path/to/photo_with_exif.jpg',
        width: 4032,
        height: 3024,
        fileSize: 5242880, // 5 MB
        format: ImageFormat.jpeg,
        modifiedTime: DateTime(2024, 1, 20, 14, 45, 0),
        exifData: ExifData(
          dateTaken: DateTime(2024, 1, 15, 14, 30, 0),
          cameraMake: 'Canon',
          cameraModel: 'EOS R5',
          gpsLocation: const GpsLocation(
            latitude: 37.774900,
            longitude: -122.419400,
          ),
          focalLength: 50.0,
          aperture: 2.8,
          iso: '400',
          exposureTime: '1/250',
        ),
      );
    });

    testWidgets('Requirement 8.2: Should display image file name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.text('test_image.jpg'), findsOneWidget);
    });

    testWidgets('Requirement 8.3: Should display image resolution (width × height)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.text('1920 × 1080'), findsOneWidget);
    });

    testWidgets('Requirement 8.4: Should display image file size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.text('2.3 MB'), findsOneWidget);
    });

    testWidgets('Requirement 8.5: Should display image format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.text('JPEG'), findsOneWidget);
    });

    testWidgets('Requirement 8.6: Should display image modified date',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.text('2024-01-15 10:30:00'), findsOneWidget);
    });

    testWidgets(
        'Requirement 8.7: Should display EXIF data when available - date taken',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: metadataWithExif),
          ),
        ),
      );

      // Should show EXIF section
      expect(find.text('EXIF 数据'), findsOneWidget);
      
      // Should show date taken
      expect(find.text('2024-01-15 14:30:00'), findsOneWidget);
    });

    testWidgets(
        'Requirement 8.7: Should display EXIF data when available - camera model',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: metadataWithExif),
          ),
        ),
      );

      // Should show camera make and model
      expect(find.text('Canon EOS R5'), findsOneWidget);
    });

    testWidgets(
        'Requirement 8.7: Should display EXIF data when available - GPS location',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: metadataWithExif),
          ),
        ),
      );

      // Should show GPS coordinates
      expect(find.text('37.774900, -122.419400'), findsOneWidget);
    });

    testWidgets('Should NOT display EXIF section when EXIF data is not available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      // Should NOT show EXIF section
      expect(find.text('EXIF 数据'), findsNothing);
    });

    testWidgets('Should display all basic info fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      // Check all labels are present
      expect(find.text('文件名'), findsOneWidget);
      expect(find.text('分辨率'), findsOneWidget);
      expect(find.text('文件大小'), findsOneWidget);
      expect(find.text('格式'), findsOneWidget);
      expect(find.text('修改日期'), findsOneWidget);
    });

    testWidgets('Should display additional EXIF fields when available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: metadataWithExif),
          ),
        ),
      );

      // Check EXIF labels
      expect(find.text('拍摄日期'), findsOneWidget);
      expect(find.text('相机型号'), findsOneWidget);
      expect(find.text('GPS 位置'), findsOneWidget);
      expect(find.text('焦距'), findsOneWidget);
      expect(find.text('光圈'), findsOneWidget);
      expect(find.text('ISO'), findsOneWidget);
      expect(find.text('曝光时间'), findsOneWidget);

      // Check EXIF values
      expect(find.text('50.0 mm'), findsOneWidget);
      expect(find.text('f/2.8'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);
      expect(find.text('1/250'), findsOneWidget);
    });

    testWidgets('Should have close button in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Should display panel title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataPanel(metadata: basicMetadata),
          ),
        ),
      );

      expect(find.text('图片信息'), findsOneWidget);
    });

    testWidgets('Static show method should display panel as bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MetadataPanel.show(context, basicMetadata),
                child: const Text('Show Panel'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show the panel
      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      // Panel should be visible
      expect(find.byType(MetadataPanel), findsOneWidget);
      expect(find.text('test_image.jpg'), findsOneWidget);
    });
  });
}
