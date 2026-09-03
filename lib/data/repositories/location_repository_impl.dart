import 'dart:async';

import '../../domain/entities/location_snapshot.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/android_location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final AndroidLocationDataSource _dataSource;

  LocationRepositoryImpl({required AndroidLocationDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Stream<LocationSnapshot> getLocationUpdates() {
    return _dataSource.locationStream;
  }

  @override
  Future<LocationSnapshot?> getLastKnownLocation() async {
    return _dataSource.getLastKnownLocation();
  }

  @override
  Future<void> startUpdates() async {
    await _dataSource.startUpdates();
  }

  @override
  Future<void> stopUpdates() async {
    await _dataSource.stopUpdates();
  }

  @override
  Future<bool> hasPermission() async {
    return _dataSource.hasPermission();
  }

  @override
  Future<bool> requestPermission() async {
    return _dataSource.requestPermission();
  }

  @override
  Future<bool> requestBackgroundPermission() async {
    return _dataSource.requestBackgroundPermission();
  }
}
