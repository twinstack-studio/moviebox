import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import '../widgets/rewards.dart';
import 'checkout_screen.dart' show validatePhone;
import 'home_shell.dart';
import 'movies_screen.dart';
import '../l10n.dart';
import '../widgets/settings_sheets.dart';
import 'insights_screen.dart';

const appVersion = '2.0.0';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final u = state.user;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Profile'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [AppColors.tintStrong, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: u == null
                      ? Icon(Icons.person, color: Colors.white, size: 30)
                      : Text(
                          _initials(u.name),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u?.name ?? tr('Guest'),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        u?.phone ??
                            tr(
                              'Sign in to save your details for faster checkout',
                            ),
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (u == null)
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: Size(40, 42)),
                    onPressed: () => showLoginSheet(context),
                    child: Text(tr('Sign in')),
                  )
                else
                  IconButton(
                    tooltip: tr('Edit profile'),
                    onPressed: () => showLoginSheet(context, editOnly: true),
                    icon: Icon(Icons.edit_outlined),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value:
                      '${state.bookings.where((b) => b.status == BookingStatus.confirmed).length}',
                  label: tr('Bookings'),
                  icon: Icons.confirmation_number_outlined,
                  onTap: () => shellTab.value = 3,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  value: '${state.watchlist.length}',
                  label: tr('Watchlist'),
                  icon: Icons.favorite_border,
                  onTap: () =>
                      Navigator.of(context).push(appRoute(WatchlistScreen())),
                ),
              ),
            ],
          ),
          RewardsCard(),
          _group(tr('Preferences'), [
            ListTile(
              leading: Icon(Icons.translate_rounded),
              title: Text(tr('Language')),
              trailing: _trail(state.language == 'ur' ? 'اردو' : tr('English')),
              onTap: () => showLanguagePicker(context),
            ),
            ListTile(
              leading: Icon(Icons.brightness_6_outlined),
              title: Text(tr('Appearance')),
              trailing: _trail(tr(themeLabel(state.themePref))),
              onTap: () => showThemePicker(context),
            ),
            ListTile(
              leading: Icon(Icons.location_city_outlined),
              title: Text(tr('City')),
              trailing: _trail(state.city),
              onTap: () => showCityPicker(context),
            ),
            ListTile(
              leading: Icon(Icons.theaters_outlined),
              title: Text(tr('Favourite cinema')),
              trailing: _trail(state.preferredCinema?.name ?? tr('Not set')),
              onTap: () => showCinemaPicker(context),
            ),
            SwitchListTile(
              secondary: Icon(Icons.notifications_outlined),
              title: Text(tr('Notifications')),
              subtitle: Text(
                tr('Show reminders & new releases'),
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              value: state.notifications,
              activeThumbColor: AppColors.primary,
              onChanged: state.setNotifications,
            ),
          ]),
          _group(tr('Support'), [
            ListTile(
              leading: Icon(Icons.insights_rounded),
              title: Text(tr('App insights')),
              subtitle: Text(
                tr('For the cinema team (demo)'),
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context).push(appRoute(InsightsScreen())),
            ),
            ListTile(
              leading: Icon(Icons.support_agent_outlined),
              title: Text(tr('Help & support')),
              trailing: Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(appRoute(HelpScreen())),
            ),
          ]),
          if (u != null)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(tr('Sign out?')),
                      content: Text(
                        tr('Your tickets stay saved on this phone.'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(tr('Cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(tr('Sign out')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) state.setUser(null);
                },
                icon: Icon(Icons.logout),
                label: Text(tr('Sign out')),
              ),
            ),
          SizedBox(height: 24),
          Center(child: BrandLogo(size: 14)),
          SizedBox(height: 6),
          Center(
            child: Text(
              tr('Version {0}', [appVersion]),
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Widget _trail(String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 150),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      Icon(Icons.chevron_right),
    ],
  );

  Widget _group(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: 24, bottom: 10, left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showLoginSheet(BuildContext context, {bool editOnly = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LoginSheet(editOnly: editOnly),
  );
}

/// Phone + OTP sign-in. Demo build uses code 1234; production plugs into
/// the cinema's SMS/OTP provider.
class _LoginSheet extends StatefulWidget {
  final bool editOnly;
  const _LoginSheet({required this.editOnly});

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  static const demoOtp = '1234';
  late int _step = widget.editOnly ? 2 : 0;
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = AppScope.read(context).user;
    if (u != null) {
      _phone.text = u.phone;
      _name.text = u.name;
      _email.text = u.email;
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final err = validatePhone(_phone.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future.delayed(Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = 1;
    });
  }

  void _verify() {
    if (_otp.text.trim() != demoOtp) {
      setState(() => _error = 'Incorrect code. Please try again.');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  void _save() {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }
    AppScope.read(context).setUser(
      UserProfile(
        name: _name.text.trim(),
        phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
        email: email,
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          widget.editOnly
              ? tr('Profile updated')
              : tr('Welcome, {0}!', [_name.text.trim().split(' ').first]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Sign in', 'Verify your number', 'Your details'];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(titles[_step]),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(switch (_step) {
            0 => tr('We\'ll text you a one-time code. No password needed.'),
            1 => tr('Enter the 4-digit code sent to {0}', [_phone.text]),
            _ => tr('Used for your tickets and receipts.'),
          }, style: TextStyle(color: AppColors.muted)),
          SizedBox(height: 18),
          if (_step == 0)
            TextField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr('Mobile number'),
                hintText: '03XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
                errorText: _error,
              ),
              onSubmitted: (_) => _sendOtp(),
            ),
          if (_step == 1) ...[
            TextField(
              controller: _otp,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                letterSpacing: 16,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                counterText: '',
                errorText: _error,
                helperText: tr('Demo code: {0}', [demoOtp]),
              ),
              onSubmitted: (_) => _verify(),
            ),
            TextButton(
              onPressed: () => setState(() {
                _step = 0;
                _otp.clear();
                _error = null;
              }),
              child: Text(tr('Change number / resend code')),
            ),
          ],
          if (_step == 2) ...[
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: tr('Full name'),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr('Email (optional)'),
                prefixIcon: Icon(Icons.mail_outline),
                errorText: _error,
              ),
            ),
          ],
          SizedBox(height: 18),
          FilledButton(
            onPressed: _busy
                ? null
                : switch (_step) {
                    0 => _sendOtp,
                    1 => _verify,
                    _ => _save,
                  },
            child: _busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(switch (_step) {
                    0 => tr('Send code'),
                    1 => tr('Verify'),
                    _ => tr('Save'),
                  }),
          ),
        ],
      ),
    );
  }
}

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Watchlist'))),
      body: AsyncView<List<Movie>>(
        load: repo.movies,
        builder: (context, movies) {
          final list = movies
              .where((m) => state.watchlist.contains(m.id))
              .toList();
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              message: tr(
                'Tap the heart on any movie to save it here for later.',
              ),
            );
          }
          return MovieGrid(movies: list);
        },
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'Money was deducted but I didn\'t get a ticket',
      'Your booking is only confirmed after payment succeeds, and every booking has a unique reference so you are never charged twice. If money was deducted without a ticket, it is automatically reversed within 3–5 working days. You can also report it below with your transaction details.',
    ),
    (
      'How do I cancel a booking?',
      'Open the ticket in the Tickets tab and tap "Cancel booking". Cancellation is free up to 2 hours before the show and the full amount is refunded to your original payment method.',
    ),
    (
      'Do I need to print my ticket?',
      'No. Show the QR code in the app at the entrance. Tickets are stored on your phone and open even without internet.',
    ),
    (
      'Why can\'t I book a show that is about to start?',
      'Online booking closes 10 minutes before each show so you are never sold a ticket for a movie that has already started. You can still buy at the box office.',
    ),
    (
      'What does "Late night" mean on a showtime?',
      'Late-night shows start after midnight. For example, a Friday late-night 12:30 AM show actually starts in the early hours of Saturday. The app shows the exact day on the chip.',
    ),
    (
      'Which payment methods are accepted?',
      'Debit/credit cards (Visa, Mastercard, UnionPay, PayPak), JazzCash, Easypaisa and Raast (SadaPay, NayaPay and bank apps).',
    ),
    (
      'Are 3D glasses included?',
      'Yes, 3D glasses are provided at the cinema for all 3D shows.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Help & support'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        tr('We\'re here to help'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    tr(
                      'Report a problem and get a reference number. Our team responds within 24 hours.',
                    ),
                    style: TextStyle(color: AppColors.muted),
                  ),
                  SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _ReportSheet(),
                      ),
                      icon: Icon(Icons.report_outlined),
                      label: Text(tr('Report a problem')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SectionHeader(tr('Frequently asked questions')),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final f in _faqs)
                  ExpansionTile(
                    shape: Border(),
                    collapsedShape: Border(),
                    iconColor: AppColors.primary,
                    title: Text(
                      tr(f.$1),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(
                        tr(f.$2),
                        style: TextStyle(color: AppColors.muted, height: 1.5),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SectionHeader(tr('Call your cinema')),
          Card(
            clipBehavior: Clip.antiAlias,
            child: AsyncView<List<Cinema>>(
              load: repo.cinemas,
              builder: (context, cinemas) => Column(
                children: [
                  for (final c in cinemas)
                    ListTile(
                      leading: Icon(Icons.theaters_outlined),
                      title: Text('MovieBox ${c.name}'),
                      subtitle: Text(
                        '${c.city} • ${c.phone}',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.call, color: AppColors.success),
                        onPressed: () => openLink(context, telUri(c.phone)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _topics = [
    'Payment deducted, no ticket',
    'Refund status',
    'Wrong show time / seats',
    'App not working',
    'Other',
  ];
  String _topic = _topics.first;
  String? _bookingId;
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_text.text.trim().length < 10) {
      setState(
        () => _error = 'Please describe the problem (at least 10 characters)',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future.delayed(Duration(milliseconds: 900));
    if (!mounted) return;
    final ref =
        'SR${stableHash(DateTime.now().toIso8601String()).toRadixString(36).toUpperCase()}';
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        duration: Duration(seconds: 6),
        content: Text(
          tr(
            'Complaint logged. Reference: {0}. We\'ll get back within 24 hours.',
            [ref],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = AppScope.of(context).bookings;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Report a problem'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _topic,
            decoration: InputDecoration(labelText: tr('Topic')),
            items: [
              for (final t in _topics)
                DropdownMenuItem(value: t, child: Text(tr(t))),
            ],
            onChanged: (v) => setState(() => _topic = v ?? _topic),
          ),
          if (bookings.isNotEmpty) ...[
            SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _bookingId,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr('Related booking')),
              items: [
                DropdownMenuItem(value: null, child: Text(tr('None'))),
                for (final b in bookings)
                  DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      '${b.movieTitle} • ${fmtDate(b.showStart)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _bookingId = v),
            ),
          ],
          SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: tr('Tell us what happened…'),
              errorText: _error,
            ),
          ),
          SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(tr('Submit')),
          ),
        ],
      ),
    );
  }
}
