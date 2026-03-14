import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/image_metadata.dart';

/// A widget that displays detailed metadata information about an image.
///
/// This widget shows:
/// - Required fields: fileName, resolution, fileSize, format, modifiedTime
/// - Optional EXIF data: dateTaken, cameraModel, cameraMake, gpsLocation
///
/// The panel is designed to be displayed as a BottomSheet or Dialog.
class MetadataPanel extends StatelessWidget {
  /// The metadata to display
  final ImageMetadata metadata;

  const MetadataPanel({
    super.key,
    required this.metadata,
  });

  /// Shows the metadata panel as a modal bottom sheet
  static void show(BuildContext context, ImageMetadata metadata) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MetadataPanel(metadata: metadata),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildHeader(context),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(context),
                  if (metadata.exifData != null) ...[
                    const SizedBox(height: 24),
                    _buildExifInfo(context),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '图片信息',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Builds the basic metadata information section
  Widget _buildBasicInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '基本信息'),
        const SizedBox(height: 12),
        _buildInfoRow(context, '文件名', metadata.fileName),
        _buildInfoRow(context, '分辨率', metadata.resolutionString),
        _buildInfoRow(context, '文件大小', metadata.fileSizeString),
        _buildInfoRow(
          context,
          '格式',
          metadata.format.toString().split('.').last.toUpperCase(),
        ),
        _buildInfoRow(
          context,
          '修改日期',
          _formatDateTime(metadata.modifiedTime),
        ),
      ],
    );
  }

  /// Builds the EXIF data information section
  Widget _buildExifInfo(BuildContext context) {
    final exif = metadata.exifData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'EXIF 数据'),
        const SizedBox(height: 12),
        if (exif.dateTaken != null)
          _buildInfoRow(context, '拍摄日期', _formatDateTime(exif.dateTaken!)),
        if (exif.cameraMake != null || exif.cameraModel != null)
          _buildInfoRow(
            context,
            '相机型号',
            _formatCameraInfo(exif.cameraMake, exif.cameraModel),
          ),
        if (exif.gpsLocation != null)
          _buildInfoRow(
            context,
            'GPS 位置',
            exif.gpsLocation!.coordinatesString,
          ),
        if (exif.focalLength != null)
          _buildInfoRow(
            context,
            '焦距',
            '${exif.focalLength!.toStringAsFixed(1)} mm',
          ),
        if (exif.aperture != null)
          _buildInfoRow(context, '光圈', 'f/${exif.aperture!.toStringAsFixed(1)}'),
        if (exif.iso != null) _buildInfoRow(context, 'ISO', exif.iso!),
        if (exif.exposureTime != null)
          _buildInfoRow(context, '曝光时间', exif.exposureTime!),
      ],
    );
  }

  /// Builds a section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  /// Builds a single information row with label and value
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a DateTime to a readable string
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Formats camera make and model information
  String _formatCameraInfo(String? make, String? model) {
    if (make != null && model != null) {
      return '$make $model';
    }
    return model ?? make ?? '';
  }
}
