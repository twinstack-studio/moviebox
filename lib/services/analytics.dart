import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where analytics events and errors are sent.
///
/// Today the app ships with [LocalAnalytics] (stored on the phone, shown in
/// the in-app Insights screen). To send the same events to Firebase, add a
/// `FirebaseAnalyticsBackend` that forwards to `FirebaseAnalytics.logEvent`
/// and `FirebaseCrashlytics.recordError`, and register it in
/// [Analytics.backends]. No screen code changes.
abstract class AnalyticsBackend {
  void logEvent(String name, Map<String, Object> params);
  void recordError(Object error, StackTrace? stack);
}

class Analytics {
  static final List<AnalyticsBackend> backends = [LocalAnalytics.instance];

  static void log(String name, [Map<String, Object> params = const {}]) {
    if (kDebugMode) debugPrint('[analytics] $name $params');
    for (final b in backends) {
      try {
        b.logEvent(name, params);
      } catch (_) {
        // Analytics must never break the app.
      }
    }
  }

  static void recordError(Object error, StackTrace? stack) {
    for (final b in backends) {
      try {
        b.recordError(error, stack);
      } catch (_) {}
    }
  }
}

class LoggedEvent {
  final String name;
  final Map<String, Object> params;
  final DateTime time;
  const LoggedEvent(this.name, this.params, this.time);

  Map<String, dynamic> toJson() => {
    'n': name,
    'p': params,
    't': time.toIso8601String(),
  };

  factory LoggedEvent.fromJson(Map<String, dynamic> j) => LoggedEvent(
    j['n'] as String,
    Map<String, Object>.from(j['p'] as Map? ?? const {}),
    DateTime.parse(j['t'] as String),
  );
}

/// On-device analytics: event counts, the booking funnel, revenue, most
/// viewed movies, recent activity and the last errors.
class LocalAnalytics implements AnalyticsBackend {
  LocalAnalytics._();
  static final instance = LocalAnalytics._();
  static const _key = 'analytics_v1';

  SharedPreferences? _prefs;
  final Map<String, int> counts = {};
  final Map<String, int> movieViews = {};
  final List<LoggedEvent> recent = [];
  final List<String> errors = [];
  int revenue = 0;
  DateTime? since;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        counts.addAll(Map<String, int>.from(j['counts'] ?? const {}));
        movieViews.addAll(Map<String, int>.from(j['movies'] ?? const {}));
        revenue = j['revenue'] as int? ?? 0;
        errors.addAll(List<String>.from(j['errors'] ?? const []));
        since = DateTime.tryParse(j['since'] as String? ?? '');
        for (final e in (j['recent'] as List? ?? const [])) {
          recent.add(LoggedEvent.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } catch (_) {
      // Corrupt or unavailable storage: start fresh.
    }
    since ??= DateTime.now();
  }

  int count(String name) => counts[name] ?? 0;

  @override
  void logEvent(String name, Map<String, Object> params) {
    counts[name] = count(name) + 1;
    if (name == 'view_movie') {
      final m = '${params['movie']}';
      movieViews[m] = (movieViews[m] ?? 0) + 1;
    }
    if (name == 'purchase') {
      revenue += (params['value'] as num?)?.toInt() ?? 0;
    }
    recent.insert(0, LoggedEvent(name, params, DateTime.now()));
    if (recent.length > 60) recent.removeLast();
    _save();
  }

  @override
  void recordError(Object error, StackTrace? stack) {
    var line = '${DateTime.now().toIso8601String().substring(0, 19)}  $error';
    if (line.length > 300) line = line.substring(0, 300);
    errors.insert(0, line);
    if (errors.length > 20) errors.removeLast();
    counts['app_error'] = count('app_error') + 1;
    _save();
  }

  void reset() {
    counts.clear();
    movieViews.clear();
    recent.clear();
    errors.clear();
    revenue = 0;
    since = DateTime.now();
    _save();
  }

  void _save() {
    try {
      _prefs?.setString(
        _key,
        jsonEncode({
          'counts': counts,
          'movies': movieViews,
          'revenue': revenue,
          'errors': errors,
          'since': since?.toIso8601String(),
          'recent': recent.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }
}
