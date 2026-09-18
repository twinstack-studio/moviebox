import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'snacks_screen.dart';
import '../l10n.dart';
import '../services/analytics.dart';

const holdDuration = Duration(minutes: 8);
const maxSeats = 10;
const bookingCutoff = Duration(minutes: 10);

String newReference() {
  final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final r = Random().nextInt(1 << 20).toRadixString(36);
  return 'CPX${t.toUpperCase()}${r.toUpperCase()}';
}

/// Entry point to the booking flow from any showtime.
void startBooking(
  BuildContext context, {
  required Movie movie,
  required Cinema cinema,
  required Showtime showtime,
}) {
  if (!showtime.start.isAfter(DateTime.now().add(bookingCutoff))) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Online booking for this show has closed.'))),
    );
    return;
  }
  Analytics.log('select_showtime', {
    'movie': movie.title,
    'cinema': cinema.name,
  });
  HapticFeedback.selectionClick();
  final draft = BookingDraft(
    movie: movie,
    cinema: cinema,
    showtime: showtime,
    reference: newReference(),
  );
  Navigator.of(context).push(appRoute(SeatScreen(draft: draft), name: 'seats'));
}

/// Finds the best block of [n] adjacent free seats: middle-back rows first,
/// then as close to the centre of the row as possible. Never splits a group
/// across an aisle.
List<Seat>? bestSeats(List<SeatRow> rows, int n) {
  const preference = ['F', 'G', 'E', 'H', 'J', 'K', 'D', 'C', 'L', 'B', 'A'];
  List<Seat>? best;
  var bestScore = double.infinity;
  for (final row in rows) {
    final rank = preference.indexOf(row.label);
    final r = rank < 0 ? preference.length : rank;
    final mid = (row.seats.length - 1) / 2;
    var start = 0;
    while (start < row.seats.length) {
      final segment = <(int, Seat)>[];
      var i = start;
      while (i < row.seats.length && row.seats[i] != null) {
        segment.add((i, row.seats[i]!));
        i++;
      }
      for (var k = 0; k + n <= segment.length; k++) {
        final block = segment.sublist(k, k + n);
        if (block.any((e) => e.$2.taken)) continue;
        final center = block.map((e) => e.$1).reduce((a, b) => a + b) / n;
        final score = r * 4 + (center - mid).abs();
        if (score < bestScore) {
          bestScore = score;
          best = block.map((e) => e.$2).toList();
        }
      }
      start = i + 1;
    }
  }
  return best;
}

class SeatScreen extends StatefulWidget {
  final BookingDraft draft;
  const SeatScreen({super.key, required this.draft});

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  int _version = 0;
  List<SeatRow> _rows = [];
  String? _lastSeatId;
  BookingDraft get draft => widget.draft;

  bool _isSelected(Seat s) => draft.seats.any((x) => x.id == s.id);

  void _toggle(Seat s) {
    if (s.taken) return;
    if (!_isSelected(s) && draft.seats.length >= maxSeats) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr('You can book up to {0} seats at a time.', [maxSeats]),
            ),
          ),
        );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (_isSelected(s)) {
        draft.seats.removeWhere((x) => x.id == s.id);
        _lastSeatId = draft.seats.isEmpty ? null : draft.seats.last.id;
      } else {
        draft.seats.add(s);
        draft.seats.sort((a, b) => a.id.compareTo(b.id));
        _lastSeatId = s.id;
      }
    });
  }

  Future<void> _pickBest() async {
    if (_rows.isEmpty) return;
    final n = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('How many seats?'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                tr(
                  'We\'ll find the best seats together, centred with a great view.',
                ),
                style: TextStyle(color: AppColors.muted),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 1; i <= 8; i++)
                    FadeSlideIn(
                      index: i,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(56, 56),
                          ),
                          onPressed: () => Navigator.pop(ctx, i),
                          child: Text(
                            '$i',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (n == null || !mounted) return;
    final block = bestSeats(_rows, n);
    if (block == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'Sorry, {0} seats together aren\'t available. Try fewer seats.',
                [n],
              ),
            ),
          ),
        );
      return;
    }
    Analytics.log('best_seats', {'count': n});
    HapticFeedback.mediumImpact();
    setState(() {
      draft.seats
        ..clear()
        ..addAll(block);
      _lastSeatId = block[block.length ~/ 2].id;
    });
  }

  /// Where a seat sits in the hall: depth 0 = front row, 1 = back row;
  /// side -1 = far left, 1 = far right.
  ({double depth, double side})? _viewFor(String id) {
    for (var r = 0; r < _rows.length; r++) {
      final row = _rows[r];
      final idx = row.seats.indexWhere((s) => s?.id == id);
      if (idx >= 0) {
        final mid = (row.seats.length - 1) / 2;
        return (
          depth: _rows.length < 2 ? 0.5 : r / (_rows.length - 1),
          side: mid == 0 ? 0 : (idx - mid) / mid,
        );
      }
    }
    return null;
  }

  Future<void> _continue() async {
    Analytics.log('select_seats', {'count': draft.seats.length});
    draft.holdExpiry = DateTime.now().add(holdDuration);
    await Navigator.of(context).push(appRoute(SnacksScreen(draft: draft)));
    if (!mounted) return;
    // Back on the seat map: release the hold and refresh availability.
    setState(() {
      draft.holdExpiry = null;
      _version++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = draft.showtime;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'MovieBox ${draft.cinema.name} • ${fmtDate(s.start)}, ${fmtTime(s.start)} • ${s.format}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: AsyncView<List<SeatRow>>(
        key: ValueKey(_version),
        load: () => repo.seatMap(s),
        builder: (context, rows) {
          _rows = rows;
          // Drop any selected seat that someone else booked meanwhile.
          final takenNow = {
            for (final r in rows)
              for (final seat in r.seats)
                if (seat != null && seat.taken) seat.id,
          };
          draft.seats.removeWhere((x) => takenNow.contains(x.id));
          final view = _lastSeatId == null ? null : _viewFor(_lastSeatId!);
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  boundaryMargin: EdgeInsets.all(60),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: FadeSlideIn(
                        child: _SeatMap(
                          rows: rows,
                          showtime: s,
                          isSelected: _isSelected,
                          onTap: _toggle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: view == null
                    ? SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: _SeatViewCard(
                          seatId: _lastSeatId!,
                          depth: view.depth,
                          side: view.side,
                        ),
                      ),
              ),
              TextButton.icon(
                onPressed: _pickBest,
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
                label: Text(
                  tr('Pick best available seats for me'),
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
              const _Legend(),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomActionBar(
        leading: draft.seats.isEmpty
            ? Text(
                tr('Select up to 10 seats\nPinch to zoom'),
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      draft.seats.length == 1
                          ? '{0} seat: {1}'
                          : '{0} seats: {1}',
                      [
                        draft.seats.length,
                        draft.seats.map((e) => e.id).join(', '),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  AnimatedPrice(
                    amount: draft.ticketTotal,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
        label: tr('Continue'),
        onPressed: draft.seats.isEmpty ? null : _continue,
      ),
    );
  }
}

class _SeatMap extends StatelessWidget {
  final List<SeatRow> rows;
  final Showtime showtime;
  final bool Function(Seat) isSelected;
  final ValueChanged<Seat> onTap;
  const _SeatMap({
    required this.rows,
    required this.showtime,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const _ScreenGlow(),
      Text(
        tr('SCREEN THIS WAY'),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 3,
          color: AppColors.muted,
        ),
      ),
      SizedBox(height: 18),
    ];
    SeatType? lastType;
    for (final row in rows) {
      if (row.type != lastType) {
        lastType = row.type;
        children.add(
          Padding(
            padding: EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              '${tr(row.type.label).toUpperCase()}  •  ${pkr(showtime.priceFor(row.type))}',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: _seatColor(row.type),
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rowLabel(row.label),
              for (final seat in row.seats)
                seat == null
                    ? SizedBox(width: 18)
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.5),
                        child: _SeatBox(
                          seat: seat,
                          selected: isSelected(seat),
                          onTap: () => onTap(seat),
                        ),
                      ),
              _rowLabel(row.label),
            ],
          ),
        ),
      );
    }
    children.add(SizedBox(height: 16));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _rowLabel(String l) => SizedBox(
    width: 24,
    child: Text(
      l,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Color _seatColor(SeatType t) => switch (t) {
  SeatType.standard => Color(0xFF9A9AB8),
  SeatType.gold => AppColors.gold,
  SeatType.platinum => AppColors.platinum,
};

class _SeatBox extends StatelessWidget {
  final Seat seat;
  final bool selected;
  final VoidCallback onTap;
  const _SeatBox({
    required this.seat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = seat.type == SeatType.platinum ? 44.0 : 26.0;
    final color = _seatColor(seat.type);
    return Semantics(
      label:
          'Seat ${seat.id}, ${seat.type.label}, ${seat.taken
              ? 'sold'
              : selected
              ? 'selected'
              : 'available'}',
      button: !seat.taken,
      child: GestureDetector(
        onTap: seat.taken ? null : onTap,
        child: AnimatedScale(
          scale: selected ? 1.15 : 1,
          duration: Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 180),
            width: w,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: seat.taken
                  ? Color(0xFF2B2B38)
                  : selected
                  ? AppColors.primary
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(9),
                bottom: Radius.circular(4),
              ),
              border: Border.all(
                color: seat.taken
                    ? Colors.transparent
                    : selected
                    ? AppColors.primary
                    : color.withValues(alpha: 0.8),
                width: 1.4,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: seat.taken
                ? Icon(Icons.close, size: 12, color: Color(0xFF55556A))
                : selected
                ? Text(
                    '${seat.number}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// The curved screen, with a soft projector glow that breathes.
class _ScreenGlow extends StatefulWidget {
  const _ScreenGlow();

  @override
  State<_ScreenGlow> createState() => _ScreenGlowState();
}

class _ScreenGlowState extends State<_ScreenGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size(380, 40),
        painter: _ScreenPainter(0.25 + 0.4 * _c.value),
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  final double glow;
  _ScreenPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width, size.height);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withValues(alpha: glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScreenPainter old) => old.glow != glow;
}

/// "View from your seat" — a small perspective preview of the screen from
/// the selected seat's position in the hall.
class _SeatViewCard extends StatelessWidget {
  final String seatId;
  final double depth;
  final double side;
  const _SeatViewCard({
    required this.seatId,
    required this.depth,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final (verdict, color) = depth < 0.2
        ? (tr('Very close to the screen'), AppColors.warning)
        : (depth >= 0.4 && side.abs() < 0.55)
        ? (tr('Perfect view'), AppColors.success)
        : (tr('Good view'), AppColors.gold);
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 118,
              height: 64,
              child: TweenAnimationBuilder<Offset>(
                tween: Tween(end: Offset(depth, side)),
                duration: Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, o, _) =>
                    CustomPaint(painter: _ViewPainter(o.dx, o.dy)),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('View from seat {0}', [seatId]),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 14, color: color),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        verdict,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  tr('Approximate preview'),
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewPainter extends CustomPainter {
  final double depth;
  final double side;
  _ViewPainter(this.depth, this.side);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16161F), Color(0xFF050507)],
        ).createShader(bounds),
    );

    // The screen shrinks with distance and shifts opposite to the seat side;
    // the far edge looks shorter, giving a sense of angle.
    final sw = w * (0.92 - depth * 0.5);
    final sh = sw * 0.42;
    final cx = w / 2 - side * w * 0.14;
    final top = 6 + depth * 6;
    final skew = side * sh * 0.18;
    final left = cx - sw / 2;
    final right = cx + sw / 2;
    final screen = Path()
      ..moveTo(left, top + max(0, skew))
      ..lineTo(right, top + max(0, -skew))
      ..lineTo(right, top + sh - max(0, -skew))
      ..lineTo(left, top + sh - max(0, skew))
      ..close();
    canvas.drawPath(
      screen,
      Paint()
        ..color = Color(0xFF9DB7FF).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      screen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8EEFF), Color(0xFF8FA8F0)],
        ).createShader(screen.getBounds()),
    );

    // Rows of seat backs in front of you (none from the front row).
    final rowsInFront = (depth * 5).round();
    final seatPaint = Paint()..color = Color(0xFF2A2A38);
    for (var r = rowsInFront - 1; r >= 0; r--) {
      final seatW = 11.0 - r * 1.4;
      if (seatW < 4) continue;
      final y = h - 3 - r * 6.5;
      final offset = -side * 5 + (r.isOdd ? seatW / 2 : 0);
      for (var x = offset - seatW; x < w + seatW; x += seatW + 3) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y - 7, seatW, 9),
            Radius.circular(3),
          ),
          seatPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ViewPainter old) =>
      old.depth != depth || old.side != side;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color fill, Color border, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1.4),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          item(Colors.transparent, Color(0xFF9A9AB8), tr('Available')),
          item(AppColors.primary, AppColors.primary, tr('Selected')),
          item(Color(0xFF2B2B38), Colors.transparent, tr('Sold')),
          item(Colors.transparent, AppColors.gold, tr('Gold')),
          item(Colors.transparent, AppColors.platinum, tr('Recliner')),
        ],
      ),
    );
  }
}

/// Countdown for the seat hold. When it runs out, the user is told clearly
/// and returned to the seat map — nothing is charged.
class HoldTimerBadge extends StatefulWidget {
  final BookingDraft draft;
  const HoldTimerBadge({super.key, required this.draft});

  @override
  State<HoldTimerBadge> createState() => _HoldTimerBadgeState();
}

class _HoldTimerBadgeState extends State<HoldTimerBadge> {
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final exp = widget.draft.holdExpiry;
    if (exp != null &&
        !exp.isAfter(DateTime.now()) &&
        !_fired &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      _fired = true;
      _expire();
    }
    setState(() {});
  }

  Future<void> _expire() async {
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.timer_off_outlined,
          color: AppColors.warning,
          size: 36,
        ),
        title: Text(tr('Seat hold expired')),
        content: Text(
          tr(
            'Your seats were held for 8 minutes. Please pick your seats again — you have not been charged.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Choose seats')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    widget.draft.seats.clear();
    widget.draft.holdExpiry = null;
    Navigator.of(
      context,
    ).popUntil((r) => r.settings.name == 'seats' || r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.draft.holdExpiry;
    if (exp == null) return SizedBox.shrink();
    var left = exp.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;
    final low = left < Duration(minutes: 2);
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    final color = low ? AppColors.warning : AppColors.muted;
    return AnimatedScale(
      // A small heartbeat every second when time is running out.
      scale: low && left.inSeconds.isEven ? 1.08 : 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              '$mm:$ss',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: low ? AppColors.warning : AppColors.text,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
