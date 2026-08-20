import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleStorageService {
  static const String _prefKey = 'saved_user_schedules_v2';
  static List<Map<String, dynamic>>? _cachedSchedules;

  /// Default baseline sample schedules
  static List<Map<String, dynamic>> _getDefaultSchedules() {
    final now = DateTime.now();
    return [
      {
        'id': 'default_1',
        'title': '전공 세미나 발표',
        'category': '발표',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오전 9:00',
        'isCompleted': true,
      },
      {
        'id': 'default_2',
        'title': '졸업논문 심사',
        'category': '시험',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오전 10:00',
        'isCompleted': true,
      },
      {
        'id': 'default_3',
        'title': '프로젝트 회의 일정',
        'category': '발표',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오후 2:30',
        'isCompleted': false,
      },
      {
        'id': 'default_4',
        'title': '중앙해커톤 본선 피칭',
        'category': '발표',
        'date': DateTime(now.year, now.month, now.day).toIso8601String(),
        'time': '오후 6:30',
        'isCompleted': false,
      },
    ];
  }

  /// Load all schedules from SharedPreferences
  static Future<List<Map<String, dynamic>>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonListStr = prefs.getString(_prefKey);

    if (jsonListStr == null || jsonListStr.isEmpty) {
      _cachedSchedules = _getDefaultSchedules();
      await _saveToPrefs();
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(jsonListStr);
        _cachedSchedules = decoded.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          if (map['date'] is String) {
            try {
              map['date'] = DateTime.parse(map['date'] as String);
            } catch (_) {}
          }
          return map;
        }).toList();
      } catch (_) {
        _cachedSchedules = _getDefaultSchedules();
        await _saveToPrefs();
      }
    }

    return List<Map<String, dynamic>>.from(_cachedSchedules!);
  }

  /// Add a new schedule
  static Future<void> addSchedule(Map<String, dynamic> schedule) async {
    final current = await loadSchedules();
    final newSchedule = Map<String, dynamic>.from(schedule);

    if (newSchedule['id'] == null) {
      newSchedule['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    newSchedule['isCompleted'] = false; // Always false when newly created!

    current.add(newSchedule);
    _cachedSchedules = current;
    await _saveToPrefs();
  }

  /// Complete a schedule by title or ID (when breathing ritual is completed via schedule flow)
  static Future<void> completeSchedule(String? titleOrId) async {
    if (titleOrId == null || titleOrId.trim().isEmpty) return;

    final current = await loadSchedules();
    bool updated = false;
    for (var s in current) {
      if (s['id'] == titleOrId || s['title'] == titleOrId) {
        s['isCompleted'] = true;
        updated = true;
      }
    }

    if (updated) {
      _cachedSchedules = current;
      await _saveToPrefs();
    }
  }

  /// Update an existing schedule
  static Future<void> updateSchedule(String id, Map<String, dynamic> updated) async {
    final current = await loadSchedules();
    for (int i = 0; i < current.length; i++) {
      if (current[i]['id'] == id || current[i]['title'] == updated['title']) {
        final map = Map<String, dynamic>.from(updated);
        current[i] = map;
        break;
      }
    }
    _cachedSchedules = current;
    await _saveToPrefs();
  }

  /// Delete schedule
  static Future<void> deleteSchedule(String id) async {
    final current = await loadSchedules();
    current.removeWhere((s) => s['id'] == id || s['title'] == id);
    _cachedSchedules = current;
    await _saveToPrefs();
  }

  static Future<void> _saveToPrefs() async {
    if (_cachedSchedules == null) return;
    final prefs = await SharedPreferences.getInstance();
    final serializable = _cachedSchedules!.map((s) {
      final copy = Map<String, dynamic>.from(s);
      if (copy['date'] is DateTime) {
        copy['date'] = (copy['date'] as DateTime).toIso8601String();
      }
      return copy;
    }).toList();

    await prefs.setString(_prefKey, jsonEncode(serializable));
  }
}
