import 'api_client.dart';

/// What kind of event this is. The server picks the reminder wording from it —
/// "내일 시험이 있어요" comes from [exam].
enum EventType {
  exam('EXAM', '시험'),
  presentation('PRESENTATION', '발표'),
  interview('INTERVIEW', '면접'),
  deadline('DEADLINE', '마감'),
  etc('ETC', '일정');

  const EventType(this.wire, this.label);

  /// The name the server uses.
  final String wire;

  /// Korean label for pickers and chips.
  final String label;

  static EventType parse(String? raw) => EventType.values
      .firstWhere((e) => e.wire == raw, orElse: () => EventType.etc);

  /// Turns one of the category chips into what the server wants.
  ///
  /// The chips start as 시험/발표/면접 but the user can type their own, so
  /// anything unrecognised becomes [etc] plus a `customCategory`. The server
  /// keeps that text and echoes it back as `displayCategory`, which is why the
  /// UI never has to remember the original label itself.
  static ({EventType type, String? custom}) fromCategory(String category) {
    final trimmed = category.trim();
    for (final type in EventType.values) {
      if (type != EventType.etc && type.label == trimmed) {
        return (type: type, custom: null);
      }
    }
    return (type: EventType.etc, custom: trimmed.isEmpty ? null : trimmed);
  }
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.startAt,
    this.customCategory,
    this.displayCategory,
  });

  final int id;
  final String title;
  final EventType eventType;
  final DateTime startAt;
  final String? customCategory;

  /// What to show as the category. The server resolves it, so prefer this over
  /// deciding between [customCategory] and [eventType] here.
  final String? displayCategory;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as int,
        title: json['title'] as String,
        eventType: EventType.parse(json['eventType'] as String?),
        startAt: DateTime.parse(json['startAt'] as String).toLocal(),
        customCategory: json['customCategory'] as String?,
        displayCategory: json['displayCategory'] as String?,
      );
}

/// Schedules that drive the reminder notifications.
class CalendarService {
  const CalendarService();

  static const CalendarService instance = CalendarService();

  ApiClient get _client => ApiClient.instance;

  /// Events in a window. `to` is exclusive, so a month view can pass the first
  /// day of the next month without double-counting it.
  Future<List<CalendarEvent>> events({DateTime? from, DateTime? to}) async {
    final data = await _client.get('/api/calendar/events', query: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    return (data as List)
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CalendarEvent> create({
    required String title,
    required EventType eventType,
    required DateTime startAt,
    String? customCategory,
  }) async {
    final data = await _client.post('/api/calendar/events', body: {
      'title': title,
      'eventType': eventType.wire,
      if (customCategory != null && customCategory.trim().isNotEmpty)
        'customCategory': customCategory.trim(),
      'startAt': startAt.toUtc().toIso8601String(),
    });
    return CalendarEvent.fromJson(data as Map<String, dynamic>);
  }

  Future<CalendarEvent> update({
    required int eventId,
    required String title,
    required EventType eventType,
    required DateTime startAt,
    String? customCategory,
  }) async {
    final data = await _client.put('/api/calendar/events/$eventId', body: {
      'title': title,
      'eventType': eventType.wire,
      if (customCategory != null && customCategory.trim().isNotEmpty)
        'customCategory': customCategory.trim(),
      'startAt': startAt.toUtc().toIso8601String(),
    });
    return CalendarEvent.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int eventId) =>
      _client.delete('/api/calendar/events/$eventId');
}
