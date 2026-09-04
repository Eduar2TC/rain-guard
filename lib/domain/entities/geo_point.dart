import 'dart:math';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  /// Calculate distance between two points in meters
  static double distanceBetween(GeoPoint a, GeoPoint b) {
    const earthRadius = 6371000; // meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final haversineFormula =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(haversineFormula), sqrt(1 - haversineFormula));

    return earthRadius * c;
  }

  /// Calculate bearing from point a to point b in degrees
  static double bearingBetween(GeoPoint a, GeoPoint b) {
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = _toDegrees(atan2(y, x));
    return (bearing + 360) % 360;
  }

  /// Project a point given bearing and distance
  static GeoPoint projectPoint(
    GeoPoint origin,
    double bearingDegrees,
    double distanceMeters,
  ) {
    const earthRadius = 6371000;
    final bearing = _toRadians(bearingDegrees);
    final lat1 = _toRadians(origin.latitude);
    final lon1 = _toRadians(origin.longitude);

    final lat2 = asin(
      sin(lat1) * cos(distanceMeters / earthRadius) +
          cos(lat1) * sin(distanceMeters / earthRadius) * cos(bearing),
    );

    final lon2 = lon1 +
        atan2(
          sin(bearing) * sin(distanceMeters / earthRadius) * cos(lat1),
          cos(distanceMeters / earthRadius) - sin(lat1) * sin(lat2),
        );

    return GeoPoint(
      latitude: _toDegrees(lat2),
      longitude: _toDegrees(lon2),
    );
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
  static double _toDegrees(double radians) => radians * 180 / pi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory GeoPoint.fromMap(Map<String, dynamic> map) => GeoPoint(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
}
