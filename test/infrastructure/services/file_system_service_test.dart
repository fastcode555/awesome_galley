import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_galley/infrastructure/services/services.dart';
import 'package:awesome_galley/domain/models/image_format.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FileSystemServiceImpl', () {
    late FileSystemService service;
    late Directory tempDir;

    setUp(() async {
      service = FileSystemServiceImpl();
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('file_system_test_');
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('getSystemImageDirectories', () {
      test('应返回平台特定的图片目录列表', () async {
        final directories = await service.getSystemImageDirectories();

        if (Platform.isWindows) {
          // Windows 平台应包含 Pictures, Desktop, Downloads
          expect(directories.any((d) => d.contains('Pictures')), isTrue);
        } else if (Platform.isMacOS || Platform.isLinux) {
          // macOS/Linux 平台应包含 Pictures, Desktop, Downloads
          expect(directories.any((d) => d.contains('Pictures')), isTrue);
        }
        // iOS/Android 应返回空列表
        // 注意：在测试环境中，我们无法直接测试移动平台
      });

      test('应只返回存在的目录', () async {
        final directories = await service.getSystemImageDirectories();

        // 验证所有返回的目录都存在
        for (final dir in directories) {
          expect(await Directory(dir).exists(), isTrue,
              reason: 'Directory should exist: $dir');
        }
      });
    });

    group('listImagesInFolder', () {
      test('应列出文件夹中的所有支持格式的图片', () async {
        // 创建测试图片文件
        final jpgFile = File(path.join(tempDir.path, 'test1.jpg'));
        final pngFile = File(path.join(tempDir.path, 'test2.png'));
        final gifFile = File(path.join(tempDir.path, 'test3.gif'));
        final txtFile = File(path.join(tempDir.path, 'test.txt'));

        await jpgFile.writeAsString('fake jpg content');
        await pngFile.writeAsString('fake png content');
        await gifFile.writeAsString('fake gif content');
        await txtFile.writeAsString('text file');

        final images = await service.listImagesInFolder(tempDir.path);

        // 应该只包含图片文件，不包含文本文件
        expect(images.length, equals(3));
        expect(images.any((img) => img.name == 'test1.jpg'), isTrue);
        expect(images.any((img) => img.name == 'test2.png'), isTrue);
        expect(images.any((img) => img.name == 'test3.gif'), isTrue);
        expect(images.any((img) => img.name == 'test.txt'), isFalse);
      });

      test('应正确识别图片格式', () async {
        final jpegFile = File(path.join(tempDir.path, 'image.jpeg'));
        final webpFile = File(path.join(tempDir.path, 'image.webp'));
        final bmpFile = File(path.join(tempDir.path, 'image.bmp'));

        await jpegFile.writeAsString('fake content');
        await webpFile.writeAsString('fake content');
        await bmpFile.writeAsString('fake content');

        final images = await service.listImagesInFolder(tempDir.path);

        expect(images.length, equals(3));

        final jpeg = images.firstWhere((img) => img.name == 'image.jpeg');
        expect(jpeg.format, equals(ImageFormat.jpeg));

        final webp = images.firstWhere((img) => img.name == 'image.webp');
        expect(webp.format, equals(ImageFormat.webp));

        final bmp = images.firstWhere((img) => img.name == 'image.bmp');
        expect(bmp.format, equals(ImageFormat.bmp));
      });

      test('应包含文件的元数据信息', () async {
        final testFile = File(path.join(tempDir.path, 'test.jpg'));
        await testFile.writeAsString('test content');

        final images = await service.listImagesInFolder(tempDir.path);

        expect(images.length, equals(1));
        final image = images.first;

        expect(image.path, equals(testFile.path));
        expect(image.name, equals('test.jpg'));
        expect(image.size, greaterThan(0));
        expect(image.modifiedTime, isA<DateTime>());
      });

      test('当目录不存在时应抛出异常', () async {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent');

        expect(
          () => service.listImagesInFolder(nonExistentPath),
          throwsA(isA<DirectoryNotFoundException>()),
        );
      });

      test('空文件夹应返回空列表', () async {
        final emptyDir = Directory(path.join(tempDir.path, 'empty'));
        await emptyDir.create();

        final images = await service.listImagesInFolder(emptyDir.path);

        expect(images, isEmpty);
      });

      test('应忽略大小写扩展名', () async {
        final upperFile = File(path.join(tempDir.path, 'test.JPG'));
        final mixedFile = File(path.join(tempDir.path, 'test2.PnG'));

        await upperFile.writeAsString('fake content');
        await mixedFile.writeAsString('fake content');

        final images = await service.listImagesInFolder(tempDir.path);

        expect(images.length, equals(2));
        expect(images.any((img) => img.format == ImageFormat.jpeg), isTrue);
        expect(images.any((img) => img.format == ImageFormat.png), isTrue);
      });
    });

    group('fileExists', () {
      test('存在的文件应返回 true', () async {
        final testFile = File(path.join(tempDir.path, 'exists.jpg'));
        await testFile.writeAsString('content');

        final exists = await service.fileExists(testFile.path);

        expect(exists, isTrue);
      });

      test('不存在的文件应返回 false', () async {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.jpg');

        final exists = await service.fileExists(nonExistentPath);

        expect(exists, isFalse);
      });
    });

    group('getModifiedTime', () {
      test('应返回文件的修改时间', () async {
        final testFile = File(path.join(tempDir.path, 'test.jpg'));
        await testFile.writeAsString('content');

        final modifiedTime = await service.getModifiedTime(testFile.path);

        expect(modifiedTime, isA<DateTime>());
        // 修改时间应该在最近
        final now = DateTime.now();
        expect(modifiedTime.isBefore(now), isTrue);
        expect(
          modifiedTime.isAfter(now.subtract(const Duration(minutes: 1))),
          isTrue,
        );
      });

      test('文件不存在时应抛出异常', () async {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.jpg');

        expect(
          () => service.getModifiedTime(nonExistentPath),
          throwsA(isA<FileNotFoundException>()),
        );
      });
    });

    group('getFileSize', () {
      test('应返回文件的大小', () async {
        final testFile = File(path.join(tempDir.path, 'test.jpg'));
        final content = 'test content with some length';
        await testFile.writeAsString(content);

        final size = await service.getFileSize(testFile.path);

        expect(size, equals(content.length));
        expect(size, greaterThan(0));
      });

      test('空文件应返回大小为 0', () async {
        final emptyFile = File(path.join(tempDir.path, 'empty.jpg'));
        await emptyFile.writeAsString('');

        final size = await service.getFileSize(emptyFile.path);

        expect(size, equals(0));
      });

      test('文件不存在时应抛出异常', () async {
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.jpg');

        expect(
          () => service.getFileSize(nonExistentPath),
          throwsA(isA<FileNotFoundException>()),
        );
      });
    });

    group('错误处理', () {
      test('DirectoryNotFoundException 应包含有意义的错误消息', () {
        final exception = DirectoryNotFoundException('Test directory not found');

        expect(
          exception.toString(),
          contains('DirectoryNotFoundException'),
        );
        expect(exception.toString(), contains('Test directory not found'));
      });

      test('FileNotFoundException 应包含有意义的错误消息', () {
        final exception = FileNotFoundException('Test file not found');

        expect(exception.toString(), contains('FileNotFoundException'));
        expect(exception.toString(), contains('Test file not found'));
      });

      test('FileSystemException 应包含错误消息和原因', () {
        final cause = Exception('Original error');
        final exception = FileSystemException('Operation failed', cause);

        expect(exception.toString(), contains('FileSystemException'));
        expect(exception.toString(), contains('Operation failed'));
        expect(exception.toString(), contains('Original error'));
      });
    });
  });
}
