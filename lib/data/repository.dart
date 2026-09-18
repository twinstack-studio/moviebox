import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';

/// Contract for all cinema data. The app only talks to this interface, so the
/// demo [MockCinemaRepository] can be replaced by a live implementation backed
/// by the cinema's ticketing API without touching any screen.
abstract class CinemaRepository {
  Future<List<Movie>> movies();
  Future<List<Cinema>> cinemas();
  Future<List<Showtime>> showtimes({
    required DateTime date,
    String? movieId,
    String? cinemaId,
    String? city,
  });
  Future<List<SeatRow>> seatMap(Showtime showtime);
  Future<List<SnackItem>> snacks();
  List<Offer> offers();

  /// Must be idempotent on [reference]: retrying never charges twice.
  Future<PaymentResult> pay({
    required String reference,
    required int amount,
    required String method,
  });
  void markSeatsBooked(String showtimeId, Iterable<String> seatIds);
  void releaseSeats(String showtimeId, Iterable<String> seatIds);
}

final CinemaRepository repo = MockCinemaRepository();

/// Stable string hash (String.hashCode is not guaranteed stable across runs).
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class MockCinemaRepository implements CinemaRepository {
  static const _latency = Duration(milliseconds: 350);
  final Map<String, Set<String>> _booked = {};
  final Map<String, PaymentResult> _payments = {};

  static final List<Movie> _movies = [
    Movie(
      id: 'spiderman-bnd',
      title: 'Spider-Man: Brand New Day',
      genres: ['Action', 'Adventure', 'Sci-Fi'],
      durationMin: 142,
      rating: 7.8,
      certificate: 'PG-13',
      language: 'English',
      synopsis:
          'Peter Parker starts over in a city that no longer remembers who he is — but new threats won\'t let the web-slinger stay in the shadows for long.',
      cast: ['Tom Holland', 'Zendaya', 'Sadie Sink', 'Jon Bernthal'],
      director: 'Destin Daniel Cretton',
      releaseDate: DateTime(2026, 7, 31),
      nowShowing: true,
      colors: [Color(0xFFB3001B), Color(0xFF1B1F5E)],
      icon: Icons.bug_report_outlined,
      formats: ['2D', '3D'],
    ),
    Movie(
      id: 'the-odyssey',
      title: 'The Odyssey',
      genres: ['Epic', 'Adventure', 'Fantasy'],
      durationMin: 165,
      rating: 8.0,
      certificate: 'PG-13',
      language: 'English',
      synopsis:
          'After the fall of Troy, Odysseus fights monsters, gods and the sea itself on a perilous voyage home to Ithaca.',
      cast: ['Matt Damon', 'Tom Holland', 'Anne Hathaway', 'Zendaya'],
      director: 'Christopher Nolan',
      releaseDate: DateTime(2026, 7, 17),
      nowShowing: true,
      colors: [Color(0xFF0F4C5C), Color(0xFF0B1320)],
      icon: Icons.sailing_outlined,
      formats: ['2D'],
    ),
    Movie(
      id: 'carry-on-jatta-4',
      title: 'Carry On Jatta 4',
      genres: ['Comedy', 'Family'],
      durationMin: 138,
      rating: 8.0,
      certificate: 'PG',
      language: 'Punjabi',
      synopsis:
          'The beloved gang returns with a fresh round of mix-ups, mistaken identities and non-stop laughter.',
      cast: ['Gippy Grewal', 'Binnu Dhillon', 'Gurpreet Ghuggi'],
      director: 'Smeep Kang',
      releaseDate: DateTime(2026, 8, 21),
      nowShowing: true,
      colors: [Color(0xFFF7A928), Color(0xFFC2410C)],
      icon: Icons.sentiment_very_satisfied_outlined,
    ),
    Movie(
      id: 'singh-vs-kaur-2',
      title: 'Singh vs Kaur 2',
      genres: ['Romance', 'Comedy'],
      durationMin: 132,
      certificate: 'PG',
      language: 'Punjabi',
      synopsis:
          'Love, family pride and one very competitive couple collide in this big-hearted romantic comedy.',
      cast: ['Gippy Grewal', 'Surveen Chawla'],
      director: 'Navaniat Singh',
      releaseDate: DateTime(2026, 8, 28),
      nowShowing: true,
      colors: [Color(0xFFE11D74), Color(0xFF4C0D3B)],
      icon: Icons.favorite_border,
    ),
    Movie(
      id: 'fall-2',
      title: 'Fall 2: Deadpoint',
      genres: ['Thriller', 'Survival'],
      durationMin: 107,
      rating: 6.8,
      certificate: '15+',
      language: 'English',
      synopsis:
          'Stranded high above the ground with no way down, two climbers must outlast the elements — and their fear.',
      cast: ['Grace Caroline Currey', 'Virginia Gardner'],
      director: 'Scott Mann',
      releaseDate: DateTime(2026, 9, 4),
      nowShowing: true,
      colors: [Color(0xFF3A7BD5), Color(0xFF0B1A2E)],
      icon: Icons.landscape_outlined,
    ),
    Movie(
      id: 'insidious-6',
      title: 'Insidious: Out of the Further',
      genres: ['Horror', 'Mystery'],
      durationMin: 110,
      rating: 6.5,
      certificate: '18+',
      language: 'English',
      synopsis:
          'A family discovers that the door to the Further never truly closed — and something is coming through.',
      cast: ['Patrick Wilson', 'Rose Byrne'],
      director: 'Jacob Chase',
      releaseDate: DateTime(2026, 8, 21),
      nowShowing: true,
      colors: [Color(0xFF4B0F0F), Color(0xFF050505)],
      icon: Icons.door_front_door_outlined,
    ),
    Movie(
      id: 'runner',
      title: 'Runner',
      genres: ['Action', 'Thriller'],
      durationMin: 118,
      rating: 6.7,
      certificate: '15+',
      language: 'English',
      synopsis:
          'A courier with nothing to lose races across the city with a package everyone wants.',
      cast: ['Ensemble Cast'],
      director: '—',
      releaseDate: DateTime(2026, 9, 4),
      nowShowing: true,
      colors: [Color(0xFF16A085), Color(0xFF0E2A2A)],
      icon: Icons.directions_run,
    ),
    Movie(
      id: 'the-uprising',
      title: 'The Uprising',
      genres: ['Drama', 'History'],
      durationMin: 128,
      rating: 7.1,
      certificate: '15+',
      language: 'English',
      synopsis:
          'Ordinary people find extraordinary courage when their town decides it has had enough.',
      cast: ['Ensemble Cast'],
      director: '—',
      releaseDate: DateTime(2026, 8, 28),
      nowShowing: true,
      colors: [Color(0xFF8E6E2F), Color(0xFF1E1608)],
      icon: Icons.flag_outlined,
    ),
    Movie(
      id: 'practical-magic-2',
      title: 'Practical Magic 2',
      genres: ['Fantasy', 'Romance'],
      durationMin: 115,
      rating: 6.1,
      certificate: 'PG-13',
      language: 'English',
      synopsis:
          'The Owens sisters return, and the family curse has a few new tricks up its sleeve.',
      cast: ['Sandra Bullock', 'Nicole Kidman'],
      director: 'Susanne Bier',
      releaseDate: DateTime(2026, 9, 11),
      nowShowing: true,
      colors: [Color(0xFF6D28D9), Color(0xFF1E0B3A)],
      icon: Icons.auto_awesome_outlined,
    ),
    Movie(
      id: 'aag-lagay-basti-mein',
      title: 'Aag Lagay Basti Mein',
      genres: ['Comedy', 'Drama'],
      durationMin: 135,
      certificate: 'PG',
      language: 'Urdu',
      synopsis:
          'A small neighbourhood feud spirals into a hilarious, chaotic battle of egos.',
      cast: ['Ensemble Cast'],
      director: '—',
      releaseDate: DateTime(2026, 9, 11),
      nowShowing: true,
      colors: [Color(0xFFEF4444), Color(0xFF7C2D12)],
      icon: Icons.local_fire_department_outlined,
    ),
    Movie(
      id: 'bol-bhavein-na-bol',
      title: 'Bol Bhavein Na Bol',
      genres: ['Romance', 'Drama'],
      durationMin: 130,
      certificate: 'PG',
      language: 'Punjabi',
      synopsis:
          'A heartfelt Punjabi love story about the things we say — and the things we never manage to.',
      cast: ['Ensemble Cast'],
      director: '—',
      releaseDate: DateTime(2026, 9, 11),
      nowShowing: true,
      colors: [Color(0xFFDB2777), Color(0xFF3B0764)],
      icon: Icons.chat_bubble_outline,
    ),
    Movie(
      id: 'avengers-doomsday',
      title: 'Avengers: Doomsday',
      genres: ['Action', 'Sci-Fi'],
      durationMin: 150,
      certificate: 'PG-13',
      language: 'English',
      synopsis:
          'Earth\'s mightiest heroes face their most dangerous enemy yet: Victor Von Doom.',
      cast: ['Robert Downey Jr.', 'Chris Hemsworth', 'Pedro Pascal'],
      director: 'Russo Brothers',
      releaseDate: DateTime(2026, 12, 18),
      nowShowing: false,
      colors: [Color(0xFF14532D), Color(0xFF020617)],
      icon: Icons.shield_outlined,
      formats: ['2D', '3D'],
    ),
    Movie(
      id: 'dune-3',
      title: 'Dune: Part Three',
      genres: ['Sci-Fi', 'Epic'],
      durationMin: 160,
      certificate: 'PG-13',
      language: 'English',
      synopsis:
          'Paul Atreides\' holy war reaches its reckoning in the final chapter of the Dune saga.',
      cast: ['Timothée Chalamet', 'Zendaya', 'Robert Pattinson'],
      director: 'Denis Villeneuve',
      releaseDate: DateTime(2026, 12, 18),
      nowShowing: false,
      colors: [Color(0xFFD97706), Color(0xFF451A03)],
      icon: Icons.wb_sunny_outlined,
    ),
  ];

  static const List<Cinema> _cinemas = [
    Cinema(
      id: 'gulberg',
      name: 'Gulberg',
      city: 'Lahore',
      address: 'Main Boulevard, Gulberg III, Lahore',
      phone: '04200000101',
      screens: 4,
      amenities: ['Dolby Sound', '3D', 'Food Court', 'Parking'],
    ),
    Cinema(
      id: 'johar-town',
      name: 'Johar Town',
      city: 'Lahore',
      address: 'Khayaban-e-Firdousi, Johar Town, Lahore',
      phone: '04200000102',
      screens: 5,
      amenities: ['Platinum Recliners', '3D', 'Parking', 'Wheelchair Access'],
    ),
    Cinema(
      id: 'clifton',
      name: 'Clifton',
      city: 'Karachi',
      address: 'Block 5, Clifton, Karachi',
      phone: '02100000103',
      screens: 4,
      amenities: ['Dolby Sound', '3D', 'Parking'],
    ),
    Cinema(
      id: 'blue-area',
      name: 'Blue Area',
      city: 'Islamabad',
      address: 'Jinnah Avenue, Blue Area, Islamabad',
      phone: '05100000104',
      screens: 5,
      amenities: ['Platinum Recliners', '3D', 'Parking'],
    ),
    Cinema(
      id: 'saddar',
      name: 'Saddar',
      city: 'Rawalpindi',
      address: 'Bank Road, Saddar, Rawalpindi',
      phone: '05100000105',
      screens: 4,
      amenities: ['3D', 'Food Court', 'Parking'],
    ),
    Cinema(
      id: 'd-ground',
      name: 'D-Ground',
      city: 'Faisalabad',
      address: 'Kohinoor Road, D-Ground, Faisalabad',
      phone: '04100000106',
      screens: 2,
      amenities: ['Dolby Sound', 'Parking'],
    ),
    Cinema(
      id: 'gt-road',
      name: 'GT Road',
      city: 'Gujranwala',
      address: 'G.T. Road, Gujranwala',
      phone: '05500000107',
      screens: 3,
      amenities: ['3D', 'Parking'],
    ),
    Cinema(
      id: 'cantt',
      name: 'Cantt',
      city: 'Sialkot',
      address: 'Paris Road, Cantt, Sialkot',
      phone: '05200000108',
      screens: 3,
      amenities: ['3D', 'Food Court'],
    ),
    Cinema(
      id: 'city-centre',
      name: 'City Centre',
      city: 'Gujrat',
      address: 'Kutchery Road, Gujrat',
      phone: '05300000109',
      screens: 2,
      amenities: ['Parking'],
    ),
    Cinema(
      id: 'latifabad',
      name: 'Latifabad',
      city: 'Hyderabad',
      address: 'Unit 7, Latifabad, Hyderabad',
      phone: '02200000110',
      screens: 3,
      amenities: ['3D', 'Food Court', 'Parking'],
    ),
  ];

  static const List<SnackItem> _snacks = [
    SnackItem(
      id: 'combo-solo',
      name: 'Solo Combo',
      description: 'Regular popcorn + regular drink',
      price: 950,
      category: 'Combos',
      icon: Icons.fastfood_outlined,
    ),
    SnackItem(
      id: 'combo-couple',
      name: 'Couple Combo',
      description: 'Large popcorn + 2 regular drinks',
      price: 1650,
      category: 'Combos',
      icon: Icons.favorite_outline,
    ),
    SnackItem(
      id: 'combo-family',
      name: 'Family Combo',
      description: '2 large popcorn + nachos + 4 drinks',
      price: 3200,
      category: 'Combos',
      icon: Icons.groups_outlined,
    ),
    SnackItem(
      id: 'popcorn-salted',
      name: 'Salted Popcorn',
      description: 'Large, freshly popped',
      price: 650,
      category: 'Popcorn',
      icon: Icons.local_movies_outlined,
    ),
    SnackItem(
      id: 'popcorn-caramel',
      name: 'Caramel Popcorn',
      description: 'Large, sweet & crunchy',
      price: 750,
      category: 'Popcorn',
      icon: Icons.cookie_outlined,
    ),
    SnackItem(
      id: 'popcorn-cheese',
      name: 'Cheese Popcorn',
      description: 'Large, loaded with cheese',
      price: 750,
      category: 'Popcorn',
      icon: Icons.local_pizza_outlined,
    ),
    SnackItem(
      id: 'nachos',
      name: 'Loaded Nachos',
      description: 'With cheese sauce & jalapeños',
      price: 850,
      category: 'Snacks',
      icon: Icons.tapas_outlined,
    ),
    SnackItem(
      id: 'fries',
      name: 'Fries',
      description: 'Crispy, lightly salted',
      price: 450,
      category: 'Snacks',
      icon: Icons.restaurant_outlined,
    ),
    SnackItem(
      id: 'drink',
      name: 'Soft Drink',
      description: 'Regular, chilled',
      price: 300,
      category: 'Drinks',
      icon: Icons.local_drink_outlined,
    ),
    SnackItem(
      id: 'water',
      name: 'Mineral Water',
      description: '500 ml',
      price: 150,
      category: 'Drinks',
      icon: Icons.water_drop_outlined,
    ),
  ];

  static const _slots = [
    (11, 0),
    (13, 15),
    (15, 30),
    (17, 45),
    (20, 0),
    (22, 15),
    (24, 30), // late night: 12:30 AM the next calendar day
  ];

  @override
  Future<List<Movie>> movies() async {
    await Future.delayed(_latency);
    return _movies;
  }

  @override
  Future<List<Cinema>> cinemas() async {
    await Future.delayed(_latency);
    return _cinemas;
  }

  @override
  List<Offer> offers() => const [
    Offer('Tuesday Treat', '25% off all tickets every Tuesday', 'TUESDAY25', [
      Color(0xFFE0243A),
      Color(0xFF6B0F1A),
    ], Icons.local_offer_outlined),
    Offer('Student Pass', '15% off with valid student ID', 'STUDENT15', [
      Color(0xFF2563EB),
      Color(0xFF1E1B4B),
    ], Icons.school_outlined),
    Offer('First Booking', '10% off your first app booking', 'MOVIEBOX10', [
      Color(0xFFF5B942),
      Color(0xFF92400E),
    ], Icons.celebration_outlined),
  ];

  /// Percentage discount on tickets for a promo code, or null if invalid.
  static int? promoPercent(String code, DateTime showDate) {
    switch (code.trim().toUpperCase()) {
      case 'MOVIEBOX10':
        return 10;
      case 'STUDENT15':
        return 15;
      case 'TUESDAY25':
        return showDate.weekday == DateTime.tuesday ? 25 : null;
    }
    return null;
  }

  List<Showtime> _generate(Cinema cinema, DateTime date) {
    final day = dayOnly(date);
    final result = <Showtime>[];
    final key = '${cinema.id}${day.year}${day.month}${day.day}';
    final rnd = Random(stableHash(key));
    for (final m in _movies.where((m) => m.nowShowing)) {
      if (rnd.nextInt(10) < 3) continue; // not every cinema plays every film
      final count = 2 + rnd.nextInt(3);
      final slots = [..._slots]..shuffle(rnd);
      for (final (h, min) in slots.take(count)) {
        final start = DateTime(day.year, day.month, day.day, h, min);
        final format = m.formats[rnd.nextInt(m.formats.length)];
        final price = (format == '3D' ? 1300 : 1000) + (h >= 17 ? 200 : 0);
        result.add(
          Showtime(
            id: '${cinema.id}_${m.id}_${start.millisecondsSinceEpoch}_$format',
            movieId: m.id,
            cinemaId: cinema.id,
            start: start,
            format: format,
            screen: 'Screen ${1 + rnd.nextInt(cinema.screens)}',
            listingDate: day,
            standardPrice: price,
          ),
        );
      }
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  @override
  Future<List<Showtime>> showtimes({
    required DateTime date,
    String? movieId,
    String? cinemaId,
    String? city,
  }) async {
    await Future.delayed(_latency);
    // Hide shows that have already started (plus a 10 minute booking cutoff)
    // so users can never book a show that is in progress.
    final cutoff = DateTime.now().add(const Duration(minutes: 10));
    final list = <Showtime>[];
    for (final c in _cinemas) {
      if (cinemaId != null && c.id != cinemaId) continue;
      if (city != null && c.city != city) continue;
      list.addAll(
        _generate(c, date).where(
          (s) =>
              (movieId == null || s.movieId == movieId) &&
              s.start.isAfter(cutoff),
        ),
      );
    }
    return list;
  }

  /// Share of seats already sold for a show (0–1). Uses the same seed as
  /// [seatMap], so the "Filling fast" badge matches the real seat map.
  static double occupancyFor(Showtime showtime) =>
      0.15 + Random(stableHash(showtime.id)).nextDouble() * 0.35;

  @override
  Future<List<SeatRow>> seatMap(Showtime showtime) async {
    await Future.delayed(_latency);
    final rnd = Random(stableHash(showtime.id));
    final booked = _booked[showtime.id] ?? const <String>{};
    final occupancy = 0.15 + rnd.nextDouble() * 0.35;
    final rows = <SeatRow>[];
    const standardRows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    const goldRows = ['J', 'K'];

    Seat seat(String row, int n, SeatType t) {
      final id = '$row$n';
      return Seat(
        id: id,
        row: row,
        number: n,
        type: t,
        taken: booked.contains(id) || rnd.nextDouble() < occupancy,
      );
    }

    for (final r in [...standardRows, ...goldRows]) {
      final type = goldRows.contains(r) ? SeatType.gold : SeatType.standard;
      final seats = <Seat?>[];
      var n = 1;
      for (var i = 0; i < 16; i++) {
        if (i == 3 || i == 12) {
          seats.add(null); // aisle
        } else {
          seats.add(seat(r, n++, type));
        }
      }
      rows.add(SeatRow(r, type, seats));
    }
    // Platinum recliners: fewer, wider seats.
    final recliners = <Seat?>[];
    for (var i = 1; i <= 8; i++) {
      recliners.add(seat('L', i, SeatType.platinum));
      if (i == 4) recliners.add(null);
    }
    rows.add(SeatRow('L', SeatType.platinum, recliners));
    return rows;
  }

  @override
  Future<List<SnackItem>> snacks() async {
    await Future.delayed(_latency);
    return _snacks;
  }

  @override
  Future<PaymentResult> pay({
    required String reference,
    required int amount,
    required String method,
  }) async {
    final existing = _payments[reference];
    if (existing != null) return existing;
    await Future.delayed(const Duration(milliseconds: 1800));
    final result = PaymentResult(
      true,
      'Payment successful',
      'TXN${stableHash(reference + method).toRadixString(36).toUpperCase()}',
    );
    _payments[reference] = result;
    return result;
  }

  @override
  void markSeatsBooked(String showtimeId, Iterable<String> seatIds) {
    _booked.putIfAbsent(showtimeId, () => {}).addAll(seatIds);
  }

  @override
  void releaseSeats(String showtimeId, Iterable<String> seatIds) {
    _booked[showtimeId]?.removeAll(seatIds);
  }

  static List<String> get cities =>
      _cinemas.map((c) => c.city).toSet().toList()..sort();

  static Movie? movieById(String id) {
    for (final m in _movies) {
      if (m.id == id) return m;
    }
    return null;
  }

  static Cinema? cinemaById(String? id) {
    for (final c in _cinemas) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Cinema> cinemasIn(String city) =>
      _cinemas.where((c) => c.city == city).toList();
}
