# RainGuard — Dependencias y Configuración

## Flutter Dependencies

```yaml
# pubspec.yaml
name: rain_guard
description: Rain alert system for cyclists

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0

  # Local Storage
  shared_preferences: ^2.2.0

  # HTTP
  http: ^1.1.0

  # Location (for foreground permission handling)
  permission_handler: ^11.0.0

  # Utilities
  intl: ^0.18.0
  uuid: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # Testing
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

## Android Dependencies

```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.rainGuard.app"
        minSdkVersion 26
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    dependencies {
        // Location
        implementation 'com.google.android.gms:play-services-location:21.0.1'

        // Coroutines
        implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'

        // Lifecycle
        implementation 'androidx.lifecycle:lifecycle-service:2.7.0'
        implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.7.0'
    }
}
```

## Android Manifest Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Location -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- Overlay -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

    <!-- Notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Network -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Foreground Service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

    <!-- Battery -->
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

    <!-- Wake Lock (for background processing) -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:name=".RainGuardApplication"
        android:label="RainGuard"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Foreground Service -->
        <service
            android:name=".service.RainMonitorForegroundService"
            android:exported="false"
            android:foregroundServiceType="location|dataSync" />

        <!-- Boot Receiver -->
        <receiver
            android:name=".receiver.BootReceiver"
            android:enabled="true"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>

        <!-- Don't optimize battery for this app -->
        <service
            android:name="androidx.lifecycle.ProcessLifecycleOwnerService"
            android:permission="android.permission.BIND_JOB_SERVICE" />

    </application>
</manifest>
```

## Open-Meteo API Configuration

```dart
// lib/core/constants/weather_api.dart
class WeatherApiConstants {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static String buildUrl({
    required double latitude,
    required double longitude,
  }) {
    return '$baseUrl'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&current=precipitation,rain,showers,temperature_2m,'
      'wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code'
      '&minutely_15=precipitation'
      '&forecast_days=1'
      '&timezone=auto';
  }
}
```

## Alert Thresholds

```dart
// lib/core/constants/alert_thresholds.dart
class AlertThresholds {
  // ETA thresholds (in minutes)
  static const double watchThreshold = 15.0;
  static const double approachingThreshold = 10.0;
  static const double warningThreshold = 5.0;
  static const double imminentThreshold = 2.0;

  // Precipitation thresholds (mm/h)
  static const double lightRain = 0.5;
  static const double moderateRain = 4.0;
  static const double heavyRain = 10.0;
  static const double extremeRain = 30.0;

  // Confidence thresholds
  static const double highConfidence = 0.80;
  static const double mediumConfidence = 0.60;
  static const double lowConfidence = 0.40;

  // Polling intervals (in seconds)
  static const int normalPolling = 300;  // 5 min
  static const int watchPolling = 300;   // 5 min
  static const int approachingPolling = 180;  // 3 min
  static const int warningPolling = 90;  // 1.5 min
  static const int rainingPolling = 180; // 3 min

  // Data freshness (in seconds)
  static const int maxDataAge = 600;  // 10 min
  static const int staleDataWarning = 300;  // 5 min

  // Hysteresis
  static const int rainConfirmationCycles = 2;
  static const int rainPassCycles = 3;
}
```

## Color Scheme

```dart
// lib/core/constants/theme.dart
class AppColors {
  static const Color safe = Color(0xFF4CAF50);      // Green
  static const Color watch = Color(0xFFFFC107);      // Amber
  static const Color approaching = Color(0xFFFF9800); // Orange
  static const Color warning = Color(0xFFFF5722);     // Deep Orange
  static const Color imminent = Color(0xFFF44336);    // Red
  static const Color raining = Color(0xFF2196F3);     // Blue
  static const Color unknown = Color(0xFF9E9E9E);     // Grey
}
```
