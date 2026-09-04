import 'package:rain_guard/domain/entities/location_snapshot.dart';

abstract class LocationRepository {
  Stream<LocationSnapshot> getLocationUpdates();
  Future<LocationSnapshot?> getLastKnownLocation();
  Future<void> startUpdates();
  Future<void> stopUpdates();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> requestBackgroundPermission();
}
