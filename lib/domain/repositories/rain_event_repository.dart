import '../entities/rain_event.dart';

abstract class RainEventRepository {
  Future<void> recordEvent(RainEvent event);
  Future<void> updateEvent(RainEvent event);
  Future<List<RainEvent>> getEvents({DateTime? from, DateTime? to});
  Future<RainEvent?> getActiveEvent();
  Future<void> clearHistory();
  Future<int> getEventCount();
}
