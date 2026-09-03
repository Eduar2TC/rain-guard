# RainGuard - Testing Guide

## Running Tests

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/domain/geo_point_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Structure

```
test/
├── domain/
│   ├── geo_point_test.dart           # GeoPoint entity tests
│   ├── location_snapshot_test.dart   # LocationSnapshot tests
│   ├── weather_test.dart             # WeatherSnapshot & PrecipitationForecast tests
│   ├── alert_test.dart               # AlertEngine, Hysteresis, AntiSpam tests
│   ├── monitoring_scheduler_test.dart # MonitoringScheduler tests
│   ├── rain_event_detector_test.dart # RainEventDetector tests
│   ├── prediction_test.dart          # Prediction engine tests
│   └── monitoring_state_test.dart    # MonitoringState & enums tests
├── widget/                           # Widget tests (to be added)
└── integration/                      # Integration tests (to be added)
```

## Test Categories

### Domain Tests

- **GeoPoint**: Distance calculation, bearing, projection
- **LocationSnapshot**: Speed conversion, movement state, accuracy
- **WeatherSnapshot**: Precipitation detection, staleness
- **PrecipitationForecast**: ETA calculation, max precipitation
- **AlertEngine**: State transitions, hysteresis, anti-spam
- **MonitoringScheduler**: Adaptive polling intervals
- **RainEventDetector**: Event lifecycle detection
- **PredictionEngine**: Rain arrival prediction

### Coverage Goals

| Module | Target Coverage |
|--------|-----------------|
| Domain | >90% |
| Data | >80% |
| Presentation | >70% |
| Overall | >80% |

## Test Cases

### Critical Paths

1. **Rain Detection**
   - No rain → Rain starts → Rain ends
   - Light rain → Heavy rain → Light rain

2. **State Transitions**
   - IDLE → WATCH → APPROACHING → WARNING → IMMINENT → RAINING → PASSED → IDLE

3. **Hysteresis**
   - Enter RAINING requires 2 confirmations
   - Leave RAINING requires 3 confirmations

4. **Anti-Spam**
   - Same state: max 1 alert per 5 minutes
   - Different states: allow transition alerts

5. **Battery Adaptation**
   - Normal: 5 min interval
   - Low battery: 10 min interval
   - Critical battery: 15 min interval

### Edge Cases

- GPS unavailable
- Network timeout
- Stale weather data
- Rapid location changes
- Multiple rapid state changes
- App backgrounded
- Battery optimization enabled

## Mocking

### Using Mockito

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([WeatherRepository, LocationRepository])
void main() {
  // Tests will use generated mocks
}
```

### Creating Mocks

```bash
flutter pub run build_runner build
```

## Continuous Integration

### GitHub Actions

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter analyze
```

## Writing New Tests

### Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/services/your_service.dart';

void main() {
  group('YourService', () {
    late YourService service;

    setUp(() {
      service = YourService();
    });

    test('does something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = service.doSomething(input);

      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### Best Practices

1. **Arrange-Act-Assert** pattern
2. **One assertion per test** when possible
3. **Descriptive test names**
4. **Use setUp for common setup**
5. **Test both success and failure paths**
6. **Test edge cases**
