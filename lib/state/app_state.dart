import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/analytics.dart';
import '../services/notifications.dart';
import '../theme.dart';

/// Rebuilds every widget while keeping all state (scroll positions, open
/// screens, form input). Used after a language or theme switch, because
/// strings and colours are read directly rather than through inherited
/// widgets.
void rebuildAllWidgets() {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  root.visitChildren(visit);
}

/// Global, persisted app state: preferences, profile, tickets and watchlist.
/// Tickets are stored on-device so they open instantly, even offline.
class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool ready = false;
  bool onboarded = false;
  String city = 'Lahore';
  String? cinemaId;
  UserProfile? user;
  bool notifications = true;

  /// 'en' or 'ur'.
  String language = 'en';

  /// 'system', 'dark' or 'light'.
  String themePref = 'dark';
  List<Booking> bookings = [];
  Set<String> watchlist = {};
  Set<String> reminders = {};

  Future<void> load() async {
    if (ready) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final p = _prefs!;
      onboarded = p.getBool('onboarded') ?? false;
      city = p.getString('city') ?? 'Lahore';
      cinemaId = p.getString('cinemaId');
      notifications = p.getBool('notifications') ?? true;
      language = p.getString('language') ?? 'en';
      themePref = p.getString('theme') ?? 'dark';
      watchlist = (p.getStringList('watchlist') ?? const []).toSet();
      reminders = (p.getStringList('reminders') ?? const []).toSet();
      final u = p.getString('user');
      if (u != null) user = UserProfile.fromJson(jsonDecode(u));
      final raw = p.getStringList('bookings') ?? const [];
      bookings = [];
      for (final b in raw) {
        try {
          bookings.add(Booking.fromJson(jsonDecode(b)));
        } catch (_) {
          // Skip a corrupt record instead of losing every ticket.
        }
      }
      for (final b in bookings.where(
        (b) => b.status == BookingStatus.confirmed,
      )) {
        repo.markSeatsBooked(b.showtimeId, b.seats);
      }
    } catch (_) {
      // Storage unavailable: run with defaults rather than crash.
    }
    _applyLanguage();
    applyTheme();
    ready = true;
    notifyListeners();
  }

  Cinema? get preferredCinema => MockCinemaRepository.cinemaById(cinemaId);

  // ---------------------------------------------------------------------------
  // Language & theme

  void _applyLanguage() {
    appLanguage = language;
    Intl.defaultLocale = language == 'ur' ? 'ur' : 'en_US';
  }

  void applyTheme() {
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppColors.light =
        themePref == 'light' ||
        (themePref == 'system' && platform == Brightness.light);
    final iconBrightness = AppColors.light ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );
  }

  /// Called when the phone switches between light and dark mode.
  void onPlatformBrightnessChanged() {
    if (themePref != 'system') return;
    applyTheme();
    _refreshEverything();
  }

  void setLanguage(String value) {
    if (language == value) return;
    language = value;
    _applyLanguage();
    _prefs?.setString('language', value);
    Analytics.log('change_language', {'language': value});
    _refreshEverything();
  }

  void setTheme(String value) {
    if (themePref == value) return;
    themePref = value;
    applyTheme();
    _prefs?.setString('theme', value);
    Analytics.log('change_theme', {'theme': value});
    _refreshEverything();
  }

  void _refreshEverything() {
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => rebuildAllWidgets());
  }

  // ---------------------------------------------------------------------------
  // Preferences

  void completeOnboarding() {
    onboarded = true;
    _prefs?.setBool('onboarded', true);
    Analytics.log('onboarding_complete', {'city': city});
    notifyListeners();
  }

  void setCity(String value) {
    if (city == value) return;
    city = value;
    if (preferredCinema?.city != value) {
      cinemaId = null;
      _prefs?.remove('cinemaId');
    }
    _prefs?.setString('city', value);
    notifyListeners();
  }

  void setCinema(Cinema? cinema) {
    cinemaId = cinema?.id;
    if (cinema != null) {
      city = cinema.city;
      _prefs?.setString('city', city);
      _prefs?.setString('cinemaId', cinema.id);
    } else {
      _prefs?.remove('cinemaId');
    }
    notifyListeners();
  }

  void setUser(UserProfile? value) {
    user = value;
    if (value == null) {
      _prefs?.remove('user');
    } else {
      _prefs?.setString('user', jsonEncode(value.toJson()));
      Analytics.log('sign_in');
    }
    notifyListeners();
  }

  void setNotifications(bool value) {
    notifications = value;
    _prefs?.setBool('notifications', value);
    Analytics.log('notifications', {'on': value});
    if (value) {
      Notifications.requestPermission();
      for (final b in bookings.where((b) => b.isUpcoming)) {
        _scheduleShowReminder(b);
      }
      for (final id in reminders) {
        _scheduleReleaseReminder(id);
      }
    } else {
      Notifications.cancelAll();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Watchlist & reminders

  bool isWatchlisted(String movieId) => watchlist.contains(movieId);

  void toggleWatchlist(String movieId) {
    final added = watchlist.add(movieId);
    if (!added) watchlist.remove(movieId);
    _prefs?.setStringList('watchlist', watchlist.toList());
    Analytics.log('watchlist', {'movie': movieId, 'added': added});
    notifyListeners();
  }

  void toggleReminder(String movieId) {
    final added = reminders.add(movieId);
    if (added) {
      Analytics.log('set_reminder', {'movie': movieId});
      if (notifications) {
        Notifications.requestPermission();
        _scheduleReleaseReminder(movieId);
      }
    } else {
      reminders.remove(movieId);
      Notifications.cancel('release-$movieId');
    }
    _prefs?.setStringList('reminders', reminders.toList());
    notifyListeners();
  }

  void _scheduleReleaseReminder(String movieId) {
    final m = MockCinemaRepository.movieById(movieId);
    if (m == null) return;
    // Bookings typically open a few days before release.
    final d = m.releaseDate.subtract(const Duration(days: 3));
    Notifications.schedule(
      key: 'release-$movieId',
      when: DateTime(d.year, d.month, d.day, 10),
      title: tr('🍿 Bookings are open: {0}', [m.title]),
      body: tr('Grab the best seats before they\'re gone!'),
    );
  }

  // ---------------------------------------------------------------------------
  // Bookings

  void addBooking(Booking booking) {
    if (bookings.any((b) => b.id == booking.id)) return;
    bookings.insert(0, booking);
    repo.markSeatsBooked(booking.showtimeId, booking.seats);
    _saveBookings();
    Analytics.log('purchase', {
      'value': booking.total,
      'movie': booking.movieTitle,
      'method': booking.paymentMethod,
      'seats': booking.seats.length,
    });
    if (notifications) {
      Notifications.requestPermission();
      _scheduleShowReminder(booking);
    }
    notifyListeners();
  }

  void _scheduleShowReminder(Booking b) {
    Notifications.schedule(
      key: 'show-${b.id}',
      when: b.showStart.subtract(const Duration(hours: 1)),
      title: tr('🎬 {0} starts in 1 hour', [b.movieTitle]),
      body: tr('{0} • {1} • Seats {2}. Doors open 15 min early.', [
        b.cinemaName,
        b.screen,
        b.seats.join(', '),
      ]),
    );
  }

  void cancelBooking(String id) {
    final i = bookings.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final b = bookings[i];
    bookings[i] = b.copyWith(status: BookingStatus.cancelled);
    repo.releaseSeats(b.showtimeId, b.seats);
    Notifications.cancel('show-$id');
    Analytics.log('cancel_booking', {'value': b.total, 'movie': b.movieTitle});
    _saveBookings();
    notifyListeners();
  }

  Booking? bookingById(String id) {
    for (final b in bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  void _saveBookings() {
    _prefs?.setStringList(
      'bookings',
      bookings.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// Subscribes the caller to rebuilds.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without subscribing (use in callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
