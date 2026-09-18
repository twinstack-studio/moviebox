import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'home_shell.dart';
import '../l10n.dart';
import '../widgets/settings_sheets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1000),
  )..forward();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final state = AppScope.read(context);
    await Future.wait([
      state.load(),
      Future.delayed(Duration(milliseconds: 1500)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      appRoute(state.onboarded ? HomeShell() : OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(
      parent: _anim,
      curve: Interval(0.4, 1, curve: Curves.easeOut),
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [AppColors.tintStrong, AppColors.bg],
            radius: 0.9,
          ),
        ),
        child: Stack(
          children: [
            // Projector beam sweeping down from the top.
            Positioned.fill(
              child: FadeTransition(
                opacity: fade,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -1.3),
                      radius: 1.1,
                      colors: [Color(0x22FFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: pop,
                    child: Shimmer(
                      base: Colors.transparent,
                      highlight: Color(0x99FFFFFF),
                      period: Duration(milliseconds: 1600),
                      child: BrandLogo(size: 32),
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeTransition(
                    opacity: fade,
                    child: Text(
                      tr('Pakistan\'s cinema, in your pocket'),
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _slides = [
    (
      Icons.movie_filter_rounded,
      'Every movie, on the big screen',
      'Browse what\'s showing across Pakistan with exact show times — no surprises at the door.',
    ),
    (
      Icons.event_seat_rounded,
      'Pick your perfect seat',
      'Live seat map with a preview of your view. Or let us pick the best seats for your group.',
    ),
    (
      Icons.qr_code_2_rounded,
      'Tickets that always work',
      'Pay with card, JazzCash or Easypaisa. Earn rewards on every booking. Your QR ticket works offline.',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index < _slides.length) {
      _page.nextPage(
        duration: Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    final state = AppScope.read(context);
    state.completeOnboarding();
    Navigator.of(context).pushReplacement(appRoute(HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    final isCityPage = _index == _slides.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  BrandLogo(size: 18),
                  Spacer(),
                  LanguageChip(),
                  SizedBox(width: 4),
                  AnimatedOpacity(
                    opacity: isCityPage ? 0 : 1,
                    duration: Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isCityPage
                          ? null
                          : () => _page.animateToPage(
                              _slides.length,
                              duration: Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                            ),
                      child: Text(
                        tr('Skip'),
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final s in _slides)
                    _Slide(icon: s.$1, title: tr(s.$2), body: tr(s.$3)),
                  const _CityStep(),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i <= _slides.length; i++)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isCityPage ? _finish : _next,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 250),
                    child: Text(
                      isCityPage ? tr('Start exploring') : tr('Next'),
                      key: ValueKey(isCityPage),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Floating(
            amplitude: 10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.4),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Icon(icon, size: 88, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 40),
          FadeSlideIn(
            index: 2,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(height: 14),
          FadeSlideIn(
            index: 4,
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityStep extends StatelessWidget {
  const _CityStep();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cinemas = MockCinemaRepository.cinemasIn(state.city);
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text(
          tr('Where do you watch?'),
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 6),
        Text(
          tr(
            'We\'ll show you showtimes near you. You can change this anytime.',
          ),
          style: TextStyle(color: AppColors.muted),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in MockCinemaRepository.cities)
              ChoiceChip(
                label: Text(c),
                selected: state.city == c,
                showCheckmark: false,
                labelStyle: appTextStyle(
                  color: state.city == c ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  state.setCity(c);
                },
              ),
          ],
        ),
        SizedBox(height: 24),
        Text(
          tr('Favourite cinema (optional)'),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        SizedBox(height: 10),
        for (final (i, c) in cinemas.indexed)
          FadeSlideIn(
            key: ValueKey(c.id),
            index: i,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(
                    Icons.theaters_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('MovieBox ${c.name}'),
                  subtitle: Text(
                    c.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: AnimatedSwitcher(
                    duration: Duration(milliseconds: 250),
                    transitionBuilder: (w, a) =>
                        ScaleTransition(scale: a, child: w),
                    child: Icon(
                      state.cinemaId == c.id
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      key: ValueKey(state.cinemaId == c.id),
                      color: state.cinemaId == c.id
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  onTap: () =>
                      state.setCinema(state.cinemaId == c.id ? null : c),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
