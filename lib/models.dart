import 'package:flutter/material.dart';

enum SeatType { standard, gold, platinum }

extension SeatTypeX on SeatType {
  String get label => switch (this) {
    SeatType.standard => 'Standard',
    SeatType.gold => 'Gold',
    SeatType.platinum => 'Platinum Recliner',
  };
}

class Movie {
  final String id;
  final String title;
  final List<String> genres;
  final int durationMin;
  final double? rating;
  final String certificate;
  final String language;
  final String synopsis;
  final List<String> cast;
  final String director;
  final DateTime releaseDate;
  final bool nowShowing;
  final List<Color> colors;
  final IconData icon;
  final List<String> formats;

  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.durationMin,
    required this.certificate,
    required this.language,
    required this.synopsis,
    required this.cast,
    required this.director,
    required this.releaseDate,
    required this.nowShowing,
    required this.colors,
    required this.icon,
    this.rating,
    this.formats = const ['2D'],
  });

  /// Bundled poster image. If it is missing, generated art is shown instead.
  String get posterAsset => 'assets/posters/$id.jpg';

  String get durationLabel => '${durationMin ~/ 60}h ${durationMin % 60}m';
}

class Cinema {
  final String id;
  final String name;
  final String city;
  final String address;
  final String phone;
  final int screens;
  final List<String> amenities;

  const Cinema({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.screens,
    this.amenities = const [],
  });

  String get mapsQuery => Uri.encodeComponent(address);
}

class Showtime {
  final String id;
  final String movieId;
  final String cinemaId;
  final DateTime start;
  final String format;
  final String screen;

  /// The calendar day the show is listed under. Late-night shows (after
  /// midnight) belong to the previous day's listing.
  final DateTime listingDate;
  final int standardPrice;

  const Showtime({
    required this.id,
    required this.movieId,
    required this.cinemaId,
    required this.start,
    required this.format,
    required this.screen,
    required this.listingDate,
    required this.standardPrice,
  });

  bool get isLateNight => start.day != listingDate.day;

  int priceFor(SeatType type) => switch (type) {
    SeatType.standard => standardPrice,
    SeatType.gold => standardPrice + 400,
    SeatType.platinum => standardPrice + 1000,
  };
}

class Seat {
  final String id;
  final String row;
  final int number;
  final SeatType type;
  final bool taken;

  const Seat({
    required this.id,
    required this.row,
    required this.number,
    required this.type,
    required this.taken,
  });
}

class SeatRow {
  final String label;
  final SeatType type;

  /// null entries are aisles / gaps.
  final List<Seat?> seats;
  const SeatRow(this.label, this.type, this.seats);
}

class SnackItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final IconData icon;

  const SnackItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
  });
}

class Offer {
  final String title;
  final String subtitle;
  final String code;
  final List<Color> colors;
  final IconData icon;
  const Offer(this.title, this.subtitle, this.code, this.colors, this.icon);
}

class UserProfile {
  final String name;
  final String phone;
  final String email;
  const UserProfile({
    required this.name,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
  };
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
  );
}

enum BookingStatus { confirmed, cancelled }

class Booking {
  final String id;
  final String movieId;
  final String movieTitle;
  final String cinemaId;
  final String cinemaName;
  final String cinemaPhone;
  final String showtimeId;
  final DateTime showStart;
  final int durationMin;
  final String format;
  final String screen;
  final List<String> seats;
  final Map<String, int> snacks; // snack name -> qty
  final int ticketTotal;
  final int snackTotal;
  final int discount;
  final int fee;
  final String paymentMethod;
  final String customerName;
  final String customerPhone;
  final DateTime createdAt;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinemaId,
    required this.cinemaName,
    required this.cinemaPhone,
    required this.showtimeId,
    required this.showStart,
    required this.durationMin,
    required this.format,
    required this.screen,
    required this.seats,
    required this.snacks,
    required this.ticketTotal,
    required this.snackTotal,
    required this.discount,
    required this.fee,
    required this.paymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.createdAt,
    this.status = BookingStatus.confirmed,
  });

  int get total => ticketTotal + snackTotal + fee - discount;
  DateTime get showEnd => showStart.add(Duration(minutes: durationMin));
  bool get isUpcoming =>
      status == BookingStatus.confirmed && showEnd.isAfter(DateTime.now());
  bool get canCancel =>
      status == BookingStatus.confirmed &&
      showStart.difference(DateTime.now()) > const Duration(hours: 2);

  Booking copyWith({BookingStatus? status}) => Booking(
    id: id,
    movieId: movieId,
    movieTitle: movieTitle,
    cinemaId: cinemaId,
    cinemaName: cinemaName,
    cinemaPhone: cinemaPhone,
    showtimeId: showtimeId,
    showStart: showStart,
    durationMin: durationMin,
    format: format,
    screen: screen,
    seats: seats,
    snacks: snacks,
    ticketTotal: ticketTotal,
    snackTotal: snackTotal,
    discount: discount,
    fee: fee,
    paymentMethod: paymentMethod,
    customerName: customerName,
    customerPhone: customerPhone,
    createdAt: createdAt,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'movieId': movieId,
    'movieTitle': movieTitle,
    'cinemaId': cinemaId,
    'cinemaName': cinemaName,
    'cinemaPhone': cinemaPhone,
    'showtimeId': showtimeId,
    'showStart': showStart.toIso8601String(),
    'durationMin': durationMin,
    'format': format,
    'screen': screen,
    'seats': seats,
    'snacks': snacks,
    'ticketTotal': ticketTotal,
    'snackTotal': snackTotal,
    'discount': discount,
    'fee': fee,
    'paymentMethod': paymentMethod,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'],
    movieId: j['movieId'],
    movieTitle: j['movieTitle'],
    cinemaId: j['cinemaId'],
    cinemaName: j['cinemaName'],
    cinemaPhone: j['cinemaPhone'] ?? '',
    showtimeId: j['showtimeId'],
    showStart: DateTime.parse(j['showStart']),
    durationMin: j['durationMin'],
    format: j['format'],
    screen: j['screen'],
    seats: List<String>.from(j['seats']),
    snacks: Map<String, int>.from(j['snacks'] ?? const {}),
    ticketTotal: j['ticketTotal'],
    snackTotal: j['snackTotal'],
    discount: j['discount'] ?? 0,
    fee: j['fee'] ?? 0,
    paymentMethod: j['paymentMethod'],
    customerName: j['customerName'] ?? '',
    customerPhone: j['customerPhone'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
    status: BookingStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => BookingStatus.confirmed,
    ),
  );
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  const PaymentResult(this.success, this.message, [this.transactionId]);
}

/// In-progress booking passed through the seat → snacks → checkout flow.
class BookingDraft {
  final Movie movie;
  final Cinema cinema;
  final Showtime showtime;

  /// Idempotency key: the same draft can never be charged twice.
  final String reference;
  List<Seat> seats = [];
  final Map<String, int> snackQty = {};
  List<SnackItem> snackCatalog = const [];
  DateTime? holdExpiry;

  BookingDraft({
    required this.movie,
    required this.cinema,
    required this.showtime,
    required this.reference,
  });

  int get ticketTotal =>
      seats.fold(0, (sum, s) => sum + showtime.priceFor(s.type));

  int get snackTotal => snackQty.entries.fold(0, (sum, e) {
    final item = snackCatalog.where((s) => s.id == e.key);
    return sum + (item.isEmpty ? 0 : item.first.price * e.value);
  });

  int get snackCount => snackQty.values.fold(0, (a, b) => a + b);

  /// Flat convenience fee per ticket, shown transparently at checkout.
  int get fee => seats.length * 50;
}
