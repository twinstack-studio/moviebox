// Generates Play Store / App Store screenshots from the real app.
//
//   flutter test screenshots/store_test.dart --update-goldens
//
// Output: screenshots/store/*.png (1080 x 1920, plus a 1024 x 500 feature
// graphic). Posters are drawn by the app itself, so no network is needed.
// Local poster images in test/screenshot_assets are used if present.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';

import 'package:parda_cinemas/data/repository.dart';
import 'package:parda_cinemas/l10n.dart';
import 'package:parda_cinemas/models.dart';
import 'package:parda_cinemas/screens/home_shell.dart';
import 'package:parda_cinemas/screens/movie_detail_screen.dart';
import 'package:parda_cinemas/screens/profile_screen.dart';
import 'package:parda_cinemas/screens/seat_screen.dart';
import 'package:parda_cinemas/screens/snacks_screen.dart';
import 'package:parda_cinemas/screens/tickets_screen.dart';
import 'package:parda_cinemas/state/app_state.dart';
import 'package:parda_cinemas/theme.dart';
import 'package:parda_cinemas/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical size of the phone drawn inside the marketing frame.
const _phone = Size(360, 760);

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    posterImageOverride = _localPoster;
    appLanguage = 'en';
    AppColors.light = false;
  });

  tearDown(() => posterImageOverride = null);

  testWidgets('01 home', (tester) async {
    final state = await _seed(tester);
    await _pumpApp(tester, state, const HomeShell());
    await _shot(
      tester,
      '01_home',
      'Every movie, on the big screen',
      'Now showing at all 10 cinemas across Pakistan',
    );
  });

  testWidgets('02 movie detail', (tester) async {
    final state = await _seed(tester);
    final movie = MockCinemaRepository.movieById('spiderman-bnd')!;
    await _pumpApp(tester, state, MovieDetailScreen(movie: movie));
    await _shot(
      tester,
      '02_showtimes',
      'Know before you go',
      'Exact start and end times, and how full each show is',
    );
  });

  testWidgets('03 seat map with view preview', (tester) async {
    final state = await _seed(tester);
    late BookingDraft draft;
    await tester.runAsync(() async => draft = await _draft());
    await _pumpApp(tester, state, SeatScreen(draft: draft));
    // Use the real "best seats" feature so the preview card appears.
    await tester.tap(find.text('Pick best available seats for me'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(
      tester,
      '03_seats',
      'See the view before you book',
      'Pick your seats, or let the app choose the best ones',
    );
  });

  testWidgets('04 snacks', (tester) async {
    final state = await _seed(tester);
    late BookingDraft draft;
    await tester.runAsync(() async => draft = await _draft());
    draft.seats = [
      const Seat(
        id: 'F7',
        row: 'F',
        number: 7,
        type: SeatType.standard,
        taken: false,
      ),
      const Seat(
        id: 'F8',
        row: 'F',
        number: 8,
        type: SeatType.standard,
        taken: false,
      ),
    ];
    draft.holdExpiry = DateTime.now().add(
      const Duration(minutes: 7, seconds: 42),
    );
    await _pumpApp(tester, state, SnacksScreen(draft: draft));
    await _shot(
      tester,
      '04_snacks',
      'Skip the snack queue',
      'Pre-order popcorn and collect it with your ticket QR',
    );
  });

  testWidgets('05 ticket', (tester) async {
    final state = await _seed(tester);
    await _pumpApp(
      tester,
      state,
      TicketDetailScreen(bookingId: state.bookings.first.id),
    );
    await _shot(
      tester,
      '05_ticket',
      'Your ticket, always with you',
      'Live countdown and a QR that works without internet',
    );
  });

  testWidgets('06 rewards', (tester) async {
    final state = await _seed(tester);
    await _pumpApp(tester, state, const ProfileScreen());
    await _shot(
      tester,
      '06_rewards',
      'Earn on every booking',
      'Parda Rewards: Silver, Gold and Platinum perks',
    );
  });

  testWidgets('07 urdu', (tester) async {
    final state = await _seed(tester, language: 'ur');
    await _pumpApp(tester, state, const HomeShell());
    await _shot(
      tester,
      '07_urdu',
      'اردو میں بھی',
      'Full Urdu support — switch language any time',
    );
  });

  testWidgets('08 light mode', (tester) async {
    final state = await _seed(tester, themePref: 'light');
    final movie = MockCinemaRepository.movieById('the-odyssey')!;
    await _pumpApp(tester, state, MovieDetailScreen(movie: movie));
    await _shot(
      tester,
      '08_light',
      'Light or dark, your choice',
      'The whole app follows your phone — or your mood',
    );
  });

  testWidgets('09 feature graphic', (tester) async {
    final state = await _seed(tester);
    tester.view.physicalSize = const Size(2048, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_FeatureGraphic(state: state));
    await tester.pump(const Duration(milliseconds: 400));
    await _precachePosters(tester);
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(
      find.byType(_FeatureGraphic),
      matchesGoldenFile('store/09_feature_graphic.png'),
    );
    await tester.pumpWidget(const SizedBox());
  });
}

// ---------------------------------------------------------------- harness

/// Cached so the image the widget asks for is the same instance we
/// pre-cached (otherwise the cache misses and the poster paints late).
final _posterCache = <String, ImageProvider>{};

ImageProvider _localPoster(Movie movie) =>
    _posterCache.putIfAbsent(movie.id, () {
      final file = File('test/screenshot_assets/${movie.id}.jpg');
      return file.existsSync()
          ? MemoryImage(file.readAsBytesSync())
          : MemoryImage(Uint8List(0));
    });

Future<void> _loadFonts() async {
  Future<void> load(String family, Iterable<String> paths) async {
    final loader = FontLoader(family);
    var any = false;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      any = true;
      loader.addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    if (any) await loader.load();
  }

  await load('Poppins', [
    for (final w in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ])
      'assets/fonts/Poppins-$w.ttf',
  ]);
  await load('NotoNaskhArabic', ['assets/fonts/NotoNaskhArabic.ttf']);

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    await load('MaterialIcons', [
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  }
}

Future<AppState> _seed(
  WidgetTester tester, {
  String language = 'en',
  String themePref = 'dark',
}) async {
  final show = DateTime.now().add(const Duration(days: 2, hours: 4));
  final booking = Booking(
    id: 'CPXM7Q2K4P',
    movieId: 'spiderman-bnd',
    movieTitle: 'Spider-Man: Brand New Day',
    cinemaId: 'johar-town',
    cinemaName: 'Parda Johar Town',
    cinemaPhone: '+923026265019',
    showtimeId: 'shot-demo',
    showStart: DateTime(show.year, show.month, show.day, 20),
    durationMin: 142,
    format: '3D',
    screen: 'Screen 3',
    seats: const ['F7', 'F8', 'F9'],
    snacks: const {'Couple Combo': 1},
    ticketTotal: 4500,
    snackTotal: 1650,
    discount: 450,
    fee: 150,
    paymentMethod: 'JazzCash',
    customerName: 'Ayesha Khan',
    customerPhone: '03001234567',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  );
  final past = Booking(
    id: 'CPXK1A9Z',
    movieId: 'the-odyssey',
    movieTitle: 'The Odyssey',
    cinemaId: 'johar-town',
    cinemaName: 'Parda Johar Town',
    cinemaPhone: '+923026265019',
    showtimeId: 'shot-past',
    showStart: DateTime.now().subtract(const Duration(days: 9)),
    durationMin: 165,
    format: '2D',
    screen: 'Screen 1',
    seats: const ['J5', 'J6'],
    snacks: const {},
    ticketTotal: 2800,
    snackTotal: 950,
    discount: 0,
    fee: 100,
    paymentMethod: 'Debit / Credit Card',
    customerName: 'Ayesha Khan',
    customerPhone: '03001234567',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
  );

  SharedPreferences.setMockInitialValues({
    'onboarded': true,
    'city': 'Lahore',
    'cinemaId': 'johar-town',
    'language': language,
    'theme': themePref,
    'notifications': true,
    'user': jsonEncode(
      const UserProfile(
        name: 'Ayesha Khan',
        phone: '03001234567',
        email: 'ayesha@example.com',
      ).toJson(),
    ),
    'watchlist': ['the-odyssey', 'dune-3'],
    'reminders': ['avengers-doomsday'],
    'bookings': [jsonEncode(booking.toJson()), jsonEncode(past.toJson())],
  });
  final state = AppState();
  await state.load();
  return state;
}

Future<BookingDraft> _draft() async {
  final movie = MockCinemaRepository.movieById('spiderman-bnd')!;
  final cinema = MockCinemaRepository.cinemaById('johar-town')!;
  final shows = await repo.showtimes(
    date: DateTime.now().add(const Duration(days: 1)),
    movieId: movie.id,
    cinemaId: cinema.id,
  );
  return BookingDraft(
    movie: movie,
    cinema: cinema,
    showtime: shows.first,
    reference: 'CPXDEMO123',
  );
}

Future<void> _pumpApp(WidgetTester tester, AppState state, Widget home) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_StoreFrame(state: state, home: home));
  await tester.pump(const Duration(milliseconds: 400));
  await _precachePosters(tester);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> _precachePosters(WidgetTester tester) async {
  final dir = Directory('test/screenshot_assets');
  if (!dir.existsSync()) return;
  final context = tester.element(find.byType(Directionality).first);
  // Real async: repository calls and image decoding need a live event loop.
  await tester.runAsync(() async {
    for (final file in dir.listSync().whereType<File>()) {
      final id = file.uri.pathSegments.last.replaceAll('.jpg', '');
      final movie = MockCinemaRepository.movieById(id);
      if (movie == null) continue;
      await precacheImage(_localPoster(movie), context);
    }
  });
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  String caption,
  String subtitle,
) async {
  _caption.value = (caption, subtitle);
  await tester.pump();
  await expectLater(
    find.byType(_StoreFrame),
    matchesGoldenFile('store/$name.png'),
  );
  await tester.pumpWidget(const SizedBox());
}

final _caption = ValueNotifier<(String, String)>(('', ''));

/// Marketing frame: headline, subtitle and the running app in a phone.
class _StoreFrame extends StatelessWidget {
  final AppState state;
  final Widget home;
  const _StoreFrame({required this.state, required this.home});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A11), Color(0xFF0B0B10), Color(0xFF2A0A12)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 38),
            ValueListenableBuilder<(String, String)>(
              valueListenable: _caption,
              builder: (context, value, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      value.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontFamilyFallback: ['NotoNaskhArabic'],
                        fontSize: 30,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontFamilyFallback: ['NotoNaskhArabic'],
                        fontSize: 15,
                        color: Color(0xFFB9B9C9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Center(child: _PhoneShell(child: _app(state, home))),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneShell extends StatelessWidget {
  final Widget child;
  const _PhoneShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF15151C),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF34343F), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: SizedBox.fromSize(size: _phone, child: child),
      ),
    );
  }
}

Widget _app(AppState state, Widget home) {
  return MediaQuery(
    data: const MediaQueryData(
      size: _phone,
      devicePixelRatio: 2,
      padding: EdgeInsets.only(top: 30, bottom: 6),
    ),
    child: AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: Locale(state.language),
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: home,
      ),
    ),
  );
}

/// 1024 x 500 Play Store feature graphic.
class _FeatureGraphic extends StatelessWidget {
  final AppState state;
  const _FeatureGraphic({required this.state});

  @override
  Widget build(BuildContext context) {
    final movies = [
      'spiderman-bnd',
      'the-odyssey',
      'dune-3',
    ].map((id) => MockCinemaRepository.movieById(id)!).toList();
    return Directionality(
      textDirection: TextDirection.ltr,
      // Outside MaterialApp there is no theme font, so text without an
      // explicit family would render in the test font.
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF12060A), Color(0xFF2B0A14)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 40, 40, 40),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLogo(size: 30),
                      const SizedBox(height: 22),
                      const Text(
                        'Book your seat\nin under a minute',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 34,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Live seat maps • Snacks pre-order • QR tickets\n'
                        'JazzCash, Easypaisa, Raast & cards • Urdu',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFFCBCBD8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final (i, m) in movies.indexed)
                        Transform.translate(
                          offset: Offset((i - 1) * 110.0, 0),
                          child: Transform.rotate(
                            angle: (i - 1) * 0.10,
                            child: SizedBox(
                              width: 200,
                              height: 290,
                              child: PosterArt(movie: m, radius: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
