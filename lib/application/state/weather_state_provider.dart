import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/precipitation_forecast.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/enums/network_state.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../data/datasources/weather_data_source.dart';
import '../../data/datasources/local_storage_data_source.dart';
import '../../data/repositories/weather_repository_impl.dart';
import 'providers.dart';

// Providers for data sources
final weatherDataSourceProvider = Provider<WeatherDataSource>((ref) {
  final dataSource = WeatherDataSource();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final localStorageDataSourceProvider = Provider<LocalStorageDataSource>((ref) {
  return LocalStorageDataSource();
});

// Provider for WeatherRepository
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final weatherDataSource = ref.watch(weatherDataSourceProvider);
  final localStorage = ref.watch(localStorageDataSourceProvider);
  final networkDataSource = ref.watch(networkDataSourceProvider);

  return WeatherRepositoryImpl(
    weatherDataSource: weatherDataSource,
    localStorage: localStorage,
    networkDataSource: networkDataSource,
  );
});

// Weather State
class WeatherState {
  final WeatherSnapshot? currentWeather;
  final PrecipitationForecast? forecast;
  final bool isLoading;
  final String? error;
  final NetworkState networkState;
  final DateTime? lastUpdate;
  final bool isDataStale;

  const WeatherState({
    this.currentWeather,
    this.forecast,
    this.isLoading = false,
    this.error,
    this.networkState = NetworkState.noConnection,
    this.lastUpdate,
    this.isDataStale = false,
  });

  bool get isRaining => currentWeather?.isRaining ?? false;

  double get precipitation => currentWeather?.precipitation ?? 0;

  double get windSpeed => currentWeather?.windSpeed ?? 0;

  double get windDirection => currentWeather?.windDirection ?? 0;

  double get windGust => currentWeather?.windGust ?? 0;

  double get temperature => currentWeather?.temperature ?? 0;

  Duration? get dataAge {
    if (lastUpdate == null) return null;
    return DateTime.now().difference(lastUpdate!);
  }

  WeatherState copyWith({
    WeatherSnapshot? currentWeather,
    PrecipitationForecast? forecast,
    bool? isLoading,
    String? error,
    NetworkState? networkState,
    DateTime? lastUpdate,
    bool? isDataStale,
  }) {
    return WeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      networkState: networkState ?? this.networkState,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isDataStale: isDataStale ?? this.isDataStale,
    );
  }
}

// Weather State Notifier
class WeatherStateNotifier extends StateNotifier<WeatherState> {
  final WeatherRepository _repository;
  Timer? _refreshTimer;

  WeatherStateNotifier(this._repository) : super(const WeatherState()) {
    _init();
  }

  Future<void> _init() async {
    // Don't fetch on init - wait for actual location from monitoring service
    // The monitoring service will call fetchWeather() with real coordinates
  }

  Future<void> fetchWeather(GeoPoint location) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _repository.getCurrentWeather(location);
      final forecast = await _repository.getPrecipitationForecast(location);
      final networkState = await _repository.getNetworkState();

      state = state.copyWith(
        currentWeather: weather,
        forecast: forecast,
        isLoading: false,
        networkState: networkState,
        lastUpdate: DateTime.now(),
        isDataStale: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void startAutoRefresh(GeoPoint location, {Duration interval = const Duration(minutes: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchWeather(location);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Provider
final weatherStateProvider = StateNotifierProvider<WeatherStateNotifier, WeatherState>((ref) {
  final repository = ref.watch(weatherRepositoryProvider);
  return WeatherStateNotifier(repository);
});
