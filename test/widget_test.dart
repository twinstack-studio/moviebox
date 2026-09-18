import 'dart:convert';

import 'package:parda_cinemas/data/repository.dart';
import 'package:parda_cinemas/main.dart';
import 'package:parda_cinemas/models.dart';
import 'package:parda_cinemas/screens/seat_screen.dart';
import 'package:parda_cinemas/state/app_state.dart';
import 'package:parda_cinemas/widgets/rewards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Booking survives a JSON round trip', () {
    final b = Booking(
      id: 'CPXTEST',
      movieId: 'the-odyssey',
      movieTitle: 'The Odyssey',
      cinemaId: 'johar-town',
      cinemaName: 'Parda Johar Town',
      cinemaPhone: '0300',
      showtimeId: 's1',
      showStart: DateTime(2026, 9, 20, 20),
      durationMin: 165,
      format: '2D',
      screen: 'Screen 2',
      seats: ['A1', 'A2'],
      snacks: {'Solo Combo': 2},
      ticketTotal: 2400,
      snackTotal: 1900,
      discount: 240,
      fee: 100,
      paymentMethod: 'JazzCash',
      customerName: 'Ali',
      customerPhone: '03001234567',
      createdAt: DateTime(2026, 9, 14),
    );
    final back = Booking.fromJson(jsonDecode(jsonEncode(b.toJson())));
    expect(back.id, b.id);
    expect(back.seats, b.seats);
    expect(back.snacks, b.snacks);
    expect(back.total, 2400 + 1900 + 100 - 240);
    expect(back.showStart, b.showStart);
  });

  test('Never lists shows that already started', () async {
    final shows = await repo.showtimes(date: DateTime.now());
    final cutoff = DateTime.now();
    expect(shows.every((s) => s.start.isAfter(cutoff)), isTrue);
  });

  test('Seat map is stable and booked seats show as taken', () async {
    final shows = await repo.showtimes(
      date: DateTime.now().add(const Duration(days: 1)),
    );
    final s = shows.first;
    final a = await repo.seatMap(s);
    final free = a
        .expand((r) => r.seats)
        .whereType<Seat>()
        .firstWhere((x) => !x.taken);
    repo.markSeatsBooked(s.id, [free.id]);
    final b = await repo.seatMap(s);
    final again = b
        .expand((r) => r.seats)
        .whereType<Seat>()
        .firstWhere((x) => x.id == free.id);
    expect(again.taken, isTrue);
    repo.releaseSeats(s.id, [free.id]);
  });

  test('Best-seat finder returns adjacent free seats in one row', () async {
    final shows = await repo.showtimes(
      date: DateTime.now().add(const Duration(days: 2)),
    );
    final rows = await repo.seatMap(shows.first);
    final block = bestSeats(rows, 3)!;
    expect(block.length, 3);
    expect(block.every((s) => !s.taken), isTrue);
    expect(block.map((s) => s.row).toSet().length, 1);
    final numbers = block.map((s) => s.number).toList()..sort();
    expect(numbers[2] - numbers[0], 2);
    expect(bestSeats(rows, 99), isNull);
  });

  test('Rewards tiers', () {
    expect(rewardPoints(2499), 24);
    expect(tierFor(0).name, 'Silver');
    expect(tierFor(700).name, 'Gold');
    expect(tierFor(2000).name, 'Platinum');
    expect(nextTier(2000), isNull);
  });

  test('Payment is idempotent per reference', () async {
    final r1 = await repo.pay(reference: 'REF1', amount: 100, method: 'Card');
    final r2 = await repo.pay(reference: 'REF1', amount: 100, method: 'Card');
    expect(r1.transactionId, r2.transactionId);
  });

  testWidgets('Onboarding leads to home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(PardaApp(state: AppState()));
    // The app has looping animations, so pump fixed durations instead of
    // pumpAndSettle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    // First frame starts the page animation, the second lets it finish.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Where do you watch?'), findsOneWidget);

    await tester.tap(find.text('Start exploring'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    // Sections further down are built lazily as you scroll, so check the
    // ones visible on the first screen.
    expect(find.text('PARDA'), findsWidgets);
    expect(find.text('What\'s your mood?'), findsOneWidget);

    // Dispose the tree so periodic timers are cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
