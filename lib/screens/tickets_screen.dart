import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'home_shell.dart';
import '../l10n.dart';
import '../services/analytics.dart';

/// Shares booking details on WhatsApp, including each person's share when
/// booking for a group.
Future<void> shareBooking(BuildContext context, Booking b) {
  Analytics.log('share_booking', {
    'movie': b.movieTitle,
    'seats': b.seats.length,
  });
  final each = b.seats.length > 1
      ? '\n💸 That\'s ${pkr((b.total / b.seats.length).round())} each'
      : '';
  final msg =
      '🎬 ${b.movieTitle}\n'
      '📍 ${b.cinemaName}\n'
      '🗓 ${fmtDateLong(b.showStart)}, ${fmtTime(b.showStart)}\n'
      '💺 Seats ${b.seats.join(', ')}\n'
      '🎟 Booking ID ${b.id}$each\n\n'
      'Booked on the MovieBox app';
  return openLink(
    context,
    Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'),
  );
}

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final upcoming = state.bookings.where((b) => b.isUpcoming).toList()
      ..sort((a, b) => a.showStart.compareTo(b.showStart));
    final past = state.bookings.where((b) => !b.isUpcoming).toList()
      ..sort((a, b) => b.showStart.compareTo(a.showStart));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('My Tickets')),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.text,
            unselectedLabelColor: AppColors.muted,
            labelStyle: appTextStyle(fontWeight: FontWeight.w700),
            dividerColor: AppColors.border,
            tabs: [
              Tab(text: tr('Upcoming')),
              Tab(text: tr('Past & Cancelled')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TicketList(
              bookings: upcoming,
              emptyText: tr(
                'No upcoming shows yet.\nYour next movie night is a tap away!',
              ),
            ),
            _TicketList(
              bookings: past,
              emptyText: tr('Your past bookings will appear here.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyText;
  const _TicketList({required this.bookings, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.confirmation_number_outlined,
        message: emptyText,
        action: FilledButton(
          onPressed: () => shellTab.value = 1,
          child: Text(tr('Browse movies')),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(20),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = bookings[i];
        final movie = MockCinemaRepository.movieById(b.movieId);
        final cancelled = b.status == BookingStatus.cancelled;
        return FadeSlideIn(
          index: i,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(
                context,
              ).push(appRoute(TicketDetailScreen(bookingId: b.id))),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 86,
                      child: movie == null
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                              ),
                            )
                          : PosterArt(
                              movie: movie,
                              showTitle: false,
                              radius: 10,
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.movieTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${fmtDate(b.showStart)} • ${fmtTime(b.showStart)}',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            tr('{0} • Seats {1}', [
                              b.cinemaName,
                              b.seats.join(', '),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 6),
                          if (cancelled)
                            InfoChip(
                              tr('Cancelled • Refunded'),
                              color: AppColors.warning,
                            )
                          else if (b.isUpcoming)
                            InfoChip(tr('Confirmed'), color: AppColors.success)
                          else
                            InfoChip(tr('Watched')),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 32,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TicketCard extends StatelessWidget {
  final Booking booking;
  const TicketCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final movie = MockCinemaRepository.movieById(b.movieId);
    final cancelled = b.status == BookingStatus.cancelled;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 100,
                  child: movie == null
                      ? SizedBox()
                      : PosterArt(movie: movie, showTitle: false, radius: 12),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.movieTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        b.cinemaName,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      SizedBox(height: 8),
                      Text(
                        fmtDateLong(b.showStart),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${fmtTime(b.showStart)} – ${fmtTime(b.showEnd)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _TicketDivider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv(tr('Seats'), b.seats.join(', ')),
                      _kv(tr('Hall'), '${b.screen} • ${b.format}'),
                      _kv(tr('Booking ID'), b.id),
                      _kv(
                        tr('Paid'),
                        tr('{0} via {1}', [pkr(b.total), tr(b.paymentMethod)]),
                      ),
                      if (b.snacks.isNotEmpty)
                        _kv(
                          tr('Snacks'),
                          b.snacks.entries
                              .map((e) => '${e.value}× ${e.key}')
                              .join(', '),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  children: [
                    GestureDetector(
                      onTap: cancelled
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.of(
                                context,
                              ).push(appRoute(QrFullScreen(booking: b)));
                            },
                      child: Opacity(
                        opacity: cancelled ? 0.2 : 1,
                        child: Hero(
                          tag: 'qr-${b.id}',
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: b.id,
                              version: QrVersions.auto,
                              size: 112,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!cancelled)
                      Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          tr('Tap to enlarge'),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (cancelled)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              ),
              child: Text(
                tr('CANCELLED • {0} refunded to {1}', [
                  pkr(b.total),
                  tr(b.paymentMethod),
                ]),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text(v, style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, c) {
                  final n = (c.maxWidth / 10).floor();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      n,
                      (_) => Container(
                        width: 5,
                        height: 1.5,
                        color: AppColors.border,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          for (final left in [true, false])
            Positioned(
              left: left ? -12 : null,
              right: left ? null : -12,
              top: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Big, bright QR for scanning at the entrance.
class QrFullScreen extends StatelessWidget {
  final Booking booking;
  const QrFullScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Hero(
                tag: 'qr-${b.id}',
                child: Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: b.id,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 28),
              FadeSlideIn(
                index: 3,
                child: Text(
                  b.movieTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              SizedBox(height: 6),
              FadeSlideIn(
                index: 4,
                child: Text(
                  tr('{0} • {1} • Seats {2}', [
                    fmtTime(b.showStart),
                    b.screen,
                    b.seats.join(', '),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 18),
              FadeSlideIn(
                index: 5,
                child: Text(
                  tr(
                    'Show this code at the entrance.\nTip: turn your screen brightness up for faster scanning.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketDetailScreen extends StatelessWidget {
  final String bookingId;
  const TicketDetailScreen({super.key, required this.bookingId});

  Future<void> _cancel(BuildContext context, Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Cancel this booking?')),
        content: Text(
          tr('{0} will be refunded to your {1} within 3–5 working days.', [
            pkr(b.total),
            tr(b.paymentMethod),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Keep booking')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Cancel booking')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    AppScope.read(context).cancelBooking(b.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('Booking cancelled. Refund of {0} initiated.', [pkr(b.total)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = AppScope.of(context).bookingById(bookingId);
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(message: tr('Ticket not found')),
      );
    }
    final arriveBy = b.showStart.subtract(Duration(minutes: 15));
    var i = 0;
    Widget stagger(Widget child) => FadeSlideIn(index: i++, child: child);
    return Scaffold(
      appBar: AppBar(title: Text(tr('Your ticket'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (b.isUpcoming)
            stagger(
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          tr('SHOWTIME IN'),
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        ShowCountdown(target: b.showStart),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          stagger(TicketCard(booking: b)),
          if (b.isUpcoming) ...[
            SizedBox(height: 16),
            stagger(
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _info(
                        Icons.login_rounded,
                        tr('Please arrive by {0}', [fmtTime(arriveBy)]),
                        tr(
                          'Doors open 15 minutes before the show. The movie starts exactly at {0}.',
                          [fmtTime(b.showStart)],
                        ),
                      ),
                      Divider(height: 24),
                      _info(
                        Icons.logout_rounded,
                        tr('Ends around {0}', [fmtTime(b.showEnd)]),
                        tr('Plan your ride home in advance.'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 16),
          stagger(
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openLink(context, telUri(b.cinemaPhone)),
                    icon: Icon(Icons.call_outlined),
                    label: Text(tr('Call cinema')),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openLink(
                      context,
                      mapsUri(Uri.encodeComponent(b.cinemaName)),
                    ),
                    icon: Icon(Icons.directions_outlined),
                    label: Text(tr('Directions')),
                  ),
                ),
              ],
            ),
          ),
          if (b.status == BookingStatus.confirmed) ...[
            SizedBox(height: 12),
            stagger(
              FilledButton.tonalIcon(
                onPressed: () => shareBooking(context, b),
                icon: Icon(Icons.share_rounded),
                label: Text(
                  b.seats.length > 1
                      ? tr('Share & split with friends')
                      : tr('Share on WhatsApp'),
                ),
              ),
            ),
          ],
          if (b.canCancel) ...[
            SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _cancel(context, b),
              icon: Icon(Icons.cancel_outlined, color: AppColors.primary),
              label: Text(
                tr('Cancel booking & get refund'),
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ] else if (b.isUpcoming)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                tr('Cancellation closes 2 hours before the show.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String title, String body) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.gold),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text(body, style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
        ),
      ),
    ],
  );
}
