import 'gps_location.dart';

/// Represents EXIF metadata extracted from an image
class ExifData {
  /// Date and time when the photo was taken
  final DateTime? dateTaken;

  /// Camera model name
  final String? cameraModel;

  /// Camera manufacturer name
  final String? cameraMake;

  /// GPS location where the photo was taken
  final GpsLocation? gpsLocation;

  /// Focal length in millimeters
  final double? focalLength;

  /// Aperture value (f-number)
  final double? aperture;

  /// ISO sensitivity value
  final String? iso;

  /// Exposure time (shutter speed)
  final String? exposureTime;

  ExifData({
    this.dateTaken,
    this.cameraModel,
    this.cameraMake,
    this.gpsLocation,
    this.focalLength,
    this.aperture,
    this.iso,
    this.exposureTime,
  });
}
