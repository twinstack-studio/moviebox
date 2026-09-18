import 'package:flutter/material.dart';

import '../services/analytics.dart';
import '../services/notifications.dart';
import '../services/display.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../l10n.dart';

/// Business dashboard for the cinema team: booking funnel, revenue, most
/// viewed movies, recent activity and errors. In this build the data comes
/// from this phone; with Firebase connected the same events flow to the
/// Firebase console for all users.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const _funnel = [
    ('Movie page views', 'view_movie'),
    ('Showtime picked', 'select_showtime'),
    ('Seats chosen', 'select_seats'),
    ('Checkout started', 'begin_checkout'),
    ('Tickets purchased', 'purchase'),
  ];

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset insights?'),
        content: Text('All analytics data on this phone will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) setState(LocalAnalytics.instance.reset);
  }

  @override
  Widget build(BuildContext context) {
    final a = LocalAnalytics.instance;
    final views = a.count('view_movie');
    final purchases = a.count('purchase');
    final conversion = views == 0 ? 0.0 : purchases / views * 100;
    final top = a.movieViews.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));
    final maxFunnel = _funnel
        .map((f) => a.count(f.$2))
        .fold(1, (m, v) => v > m ? v : m);
    var i = 0;
    Widget stagger(Widget child) => FadeSlideIn(index: i++, child: child);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('App insights')),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            tooltip: 'Reset',
            icon: Icon(Icons.delete_outline),
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          stagger(const _Banner()),
          SizedBox(height: 16),
          stagger(
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Revenue',
                    value: pkr(a.revenue),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: tr('Bookings'),
                    value: '$purchases',
                    icon: Icons.confirmation_number_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          stagger(
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Conversion',
                    value: '${conversion.toStringAsFixed(1)}%',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Errors',
                    value: '${a.count('app_error')}',
                    icon: Icons.bug_report_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          _title('Booking funnel'),
          for (final (n, f) in _funnel.indexed)
            stagger(
              _Bar(
                label: f.$1,
                value: a.count(f.$2),
                max: maxFunnel,
                note: n == 0
                    ? null
                    : _pct(a.count(f.$2), a.count(_funnel[n - 1].$2)),
              ),
            ),
          _title('Most viewed movies'),
          if (top.isEmpty)
            _muted('Open a few movies to see data here.')
          else
            for (final e in top.take(5))
              stagger(
                _Bar(
                  label: e.key,
                  value: e.value,
                  max: top.first.value,
                  color: AppColors.gold,
                ),
              ),
          _title('Recent activity'),
          if (a.recent.isEmpty)
            _muted('No events yet.')
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final e in a.recent.take(15))
                    ListTile(
                      dense: true,
                      leading: Icon(
                        _iconFor(e.name),
                        color: AppColors.primary,
                        size: 20,
                      ),
                      title: Text(
                        e.name,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: e.params.isEmpty
                          ? null
                          : Text(
                              e.params.entries
                                  .map((p) => '${p.key}: ${p.value}')
                                  .join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                      trailing: Text(
                        _ago(e.time),
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          _title('Errors & crashes'),
          if (a.errors.isEmpty)
            _muted('No errors recorded 🎉')
          else
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in a.errors.take(10))
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          e,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await Notifications.requestPermission();
              await Notifications.showNow(
                key: 'test',
                title: '🎬 Test reminder from Parda',
                body: 'Notifications are working on this phone.',
              );
            },
            icon: Icon(Icons.notifications_active_outlined),
            label: Text('Send a test notification'),
          ),
          SizedBox(height: 10),
          Text(
            'Tracking since ${fmtDate(a.since ?? DateTime.now())}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _pct(int value, int previous) =>
      previous == 0 ? '—' : '${(value / previous * 100).round()}% of previous';

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  static IconData _iconFor(String name) => switch (name) {
    'purchase' => Icons.shopping_bag_outlined,
    'view_movie' => Icons.movie_outlined,
    'select_showtime' => Icons.schedule_rounded,
    'select_seats' || 'best_seats' => Icons.event_seat_outlined,
    'begin_checkout' => Icons.credit_card_rounded,
    'cancel_booking' => Icons.cancel_outlined,
    'share_booking' => Icons.share_rounded,
    'app_open' => Icons.phone_android_rounded,
    _ => Icons.bolt_rounded,
  };

  Widget _title(String t) => Padding(
    padding: EdgeInsets.only(top: 24, bottom: 12),
    child: Text(t, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
  );

  Widget _muted(String t) => Text(t, style: TextStyle(color: AppColors.muted));
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local demo mode',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'These numbers come from this phone. Once Firebase is connected, the same events and crash reports from every user appear live in the Firebase console.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (Display.activeMode != null) ...[
                  SizedBox(height: 6),
                  Text(
                    'Display: ${Display.activeMode}',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String? note;
  final Color? color;
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    this.note,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (note != null)
                Text(
                  '$note   ',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              Text('$value', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: AppColors.surface2,
                color: color ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
