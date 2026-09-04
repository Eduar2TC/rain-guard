import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/channels/method_channel_service.dart';
import '../../platform/channels/event_channel_service.dart';
import '../../data/datasources/android_location_datasource.dart';
import '../../data/datasources/network_data_source.dart';

// Shared providers for platform channels and data sources
final methodChannelServiceProvider = Provider<MethodChannelService>((ref) {
  return MethodChannelService();
});

final eventChannelServiceProvider = Provider<EventChannelService>((ref) {
  return EventChannelService();
});

final androidLocationDataSourceProvider = Provider<AndroidLocationDataSource>((ref) {
  final methodChannel = ref.watch(methodChannelServiceProvider);
  final eventChannel = ref.watch(eventChannelServiceProvider);
  return AndroidLocationDataSource(
    methodChannel: methodChannel,
    eventChannel: eventChannel,
  );
});

final networkDataSourceProvider = Provider<NetworkDataSource>((ref) {
  final dataSource = NetworkDataSource();
  dataSource.init();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});
