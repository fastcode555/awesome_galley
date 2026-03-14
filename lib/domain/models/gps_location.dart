/// Represents GPS location data from EXIF metadata
class GpsLocation {
  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  const GpsLocation({
    required this.latitude,
    required this.longitude,
  });

  /// Get formatted coordinates string
  String get coordinatesString =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
