import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'cinemas_screen.dart';
import 'home_shell.dart';
import 'movie_detail_screen.dart';
import 'movies_screen.dart';
import '../l10n.dart';
import '../services/analytics.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _version = 0;

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _version++);
    await Future.delayed(Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncView<List<Movie>>(
          key: ValueKey(_version),
          load: repo.movies,
          loading: HomeSkeleton(),
          builder: (context, movies) {
            final showing = movies.where((m) => m.nowShowing).toList();
            final soon = movies.where((m) => !m.nowShowing).toList();
            final upcoming = state.bookings.where((b) => b.isUpcoming).toList()
              ..sort((a, b) => a.showStart.compareTo(b.showStart));
            var i = 0;
            Widget section(Widget child) => SliverToBoxAdapter(
              child: FadeSlideIn(index: i++, child: child),
            );
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  section(_TopBar(city: state.city)),
                  if (upcoming.isNotEmpty)
                    section(_NextShowBanner(upcoming.first)),
                  section(_HeroCarousel(movies: showing.take(5).toList())),
                  section(SectionHeader(tr('What\'s your mood?'))),
                  section(_MoodPicker(movies: showing)),
                  section(
                    SectionHeader(
                      tr('Now Showing'),
                      action: tr('See all'),
                      onAction: () {
                        moviesTabIndex.value = 0;
                        shellTab.value = 1;
                      },
                    ),
                  ),
                  section(_PosterRow(movies: showing, heroPrefix: 'now')),
                  section(_CinemaCard(cinema: state.preferredCinema)),
                  section(SectionHeader(tr('Offers & Deals'))),
                  section(const _OffersRow()),
                  section(
                    SectionHeader(
                      tr('Coming Soon'),
                      action: tr('See all'),
                      onAction: () {
                        moviesTabIndex.value = 1;
                        shellTab.value = 1;
                      },
                    ),
                  ),
                  section(
                    _PosterRow(
                      movies: soon,
                      comingSoon: true,
                      heroPrefix: 'soon',
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String city;
  const _TopBar({required this.city});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return tr('Good morning');
    if (h < 17) return tr('Good afternoon');
    return tr('Good evening');
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    final name = user?.name.split(' ').first;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandLogo(size: 20),
                SizedBox(height: 6),
                Text(
                  name == null
                      ? '$_greeting!'
                      // Separate key so Urdu can drop the "!", which bidi
                      // would otherwise push to the wrong end of the line.
                      : tr('{0}, {1}!', [_greeting, name]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showCityPicker(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      child: Text(
                        city,
                        key: ValueKey(city),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextShowBanner extends StatelessWidget {
  final Booking booking;
  const _NextShowBanner(this.booking);

  @override
  Widget build(BuildContext context) {
    final diff = booking.showStart.difference(DateTime.now());
    final when = diff.inMinutes < 60
        ? tr('in {0} min', [diff.inMinutes.clamp(0, 59)])
        : diff.inHours < 24
        ? tr('in {0}h {1}m', [diff.inHours, diff.inMinutes % 60])
        : fmtDate(booking.showStart);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.success.withValues(alpha: 0.12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => shellTab.value = 3,
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                const _PulsingDot(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Your next show starts {0}', [when]),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${booking.movieTitle} • ${fmtTime(booking.showStart)} • ${booking.cinemaName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10 + 14 * _c.value,
              height: 10 + 14 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(
                  alpha: 0.4 * (1 - _c.value),
                ),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  final List<Movie> movies;
  const _HeroCarousel({required this.movies});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController(viewportFraction: 0.86);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients || widget.movies.isEmpty) return;
      final next = (_index + 1) % widget.movies.length;
      _controller.animateToPage(
        next,
        duration: Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return SizedBox.shrink();
    return Column(
      children: [
        SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.movies.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final m = widget.movies[i];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  var page = _index.toDouble();
                  if (_controller.hasClients &&
                      _controller.position.hasContentDimensions) {
                    page = _controller.page ?? page;
                  }
                  final delta = page - i;
                  final scale = (1 - delta.abs() * 0.08).clamp(0.9, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: PressableScale(
                        onTap: () => Navigator.of(context).push(
                          appRoute(
                            MovieDetailScreen(
                              movie: m,
                              heroTag: 'hero-${m.id}',
                            ),
                          ),
                        ),
                        child: _HeroCard(movie: m, parallax: delta),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.movies.length; i++)
              AnimatedContainer(
                duration: Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Movie movie;
  final double parallax;
  const _HeroCard({required this.movie, required this.parallax});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: movie.colors.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset(parallax * 70, 0),
                  child: BlurredBackdrop(movie: movie),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Transform.translate(
                  offset: Offset(parallax * -24, 0),
                  child: SizedBox(
                    width: 132,
                    child: Hero(
                      tag: 'hero-${movie.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: PosterArt(movie: movie, radius: 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Shrinks instead of overflowing when the label is
                          // long (Urdu, or a long certificate).
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  InfoChip(
                                    movie.certificate,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  if (movie.formats.contains('3D'))
                                    InfoChip('3D', color: AppColors.gold),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          if (movie.rating != null) RatingBadge(movie.rating!),
                        ],
                      ),
                      Spacer(),
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${movie.genres.map(tr).join(' • ')}  |  ${movie.durationLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                tr('Book Tickets'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "What's your mood?" — pick a feeling, get matching films instantly.
class _MoodPicker extends StatefulWidget {
  final List<Movie> movies;
  const _MoodPicker({required this.movies});

  @override
  State<_MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<_MoodPicker> {
  static const _moods = [
    (
      'Laugh',
      Icons.sentiment_very_satisfied_rounded,
      Color(0xFFF59E0B),
      ['Comedy', 'Family'],
    ),
    (
      'Thrill',
      Icons.bolt_rounded,
      Color(0xFF3B82F6),
      ['Action', 'Thriller', 'Survival'],
    ),
    (
      'Scare',
      Icons.nights_stay_rounded,
      Color(0xFF8B5CF6),
      ['Horror', 'Mystery'],
    ),
    ('Love', Icons.favorite_rounded, Color(0xFFEC4899), ['Romance']),
    (
      'Epic',
      Icons.public_rounded,
      Color(0xFF10B981),
      ['Epic', 'Adventure', 'Sci-Fi', 'Fantasy'],
    ),
    (
      'Feels',
      Icons.water_drop_rounded,
      Color(0xFF06B6D4),
      ['Drama', 'History'],
    ),
  ];
  int _sel = 0;

  @override
  Widget build(BuildContext context) {
    final mood = _moods[_sel];
    final list = widget.movies
        .where((m) => m.genres.any(mood.$4.contains))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _moods.length,
            separatorBuilder: (_, _) => SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = _moods[i];
              final sel = i == _sel;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Analytics.log('mood_pick', {'mood': m.$1});
                  setState(() => _sel = i);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel
                        ? m.$3.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? m.$3 : AppColors.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: sel ? 1.25 : 1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Icon(m.$2, color: m.$3, size: 20),
                      ),
                      SizedBox(width: 8),
                      Text(
                        tr(m.$1),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: sel ? AppColors.text : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: Offset(0.06, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_sel),
            child: list.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Text(
                      tr(
                        'Nothing for this mood right now — new releases land every Friday!',
                      ),
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : _PosterRow(movies: list, heroPrefix: 'mood$_sel'),
          ),
        ),
      ],
    );
  }
}

class _PosterRow extends StatelessWidget {
  final List<Movie> movies;
  final bool comingSoon;
  final String heroPrefix;
  const _PosterRow({
    required this.movies,
    required this.heroPrefix,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: comingSoon ? 262 : 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: movies.length,
        separatorBuilder: (_, _) => SizedBox(width: 14),
        itemBuilder: (context, i) => FadeSlideIn(
          index: i,
          from: Offset(0.25, 0),
          child: MovieTile(
            movie: movies[i],
            width: 140,
            comingSoon: comingSoon,
            heroTag: '$heroPrefix-${movies[i].id}',
          ),
        ),
      ),
    );
  }
}

/// Poster with title below; used in rows and grids.
class MovieTile extends StatelessWidget {
  final Movie movie;
  final double? width;
  final bool comingSoon;
  final String? heroTag;
  const MovieTile({
    super.key,
    required this.movie,
    this.width,
    this.comingSoon = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    Widget poster = PosterArt(movie: movie);
    if (heroTag != null) {
      poster = Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: poster),
      );
    }
    return SizedBox(
      width: width,
      child: PressableScale(
        onTap: () => Navigator.of(
          context,
        ).push(appRoute(MovieDetailScreen(movie: movie, heroTag: heroTag))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The poster takes whatever height is left after the labels, so
            // taller scripts (Urdu) or larger text can never overflow.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  poster,
                  if (movie.rating != null && !comingSoon)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RatingBadge(movie.rating!),
                    ),
                  if (comingSoon)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.black54,
                        shape: CircleBorder(),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: tr('Remind me'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            state.toggleReminder(movie.id);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.reminders.contains(movie.id)
                                        ? tr(
                                            'We\'ll remind you when bookings open for {0}',
                                            [movie.title],
                                          )
                                        : tr('Reminder removed'),
                                  ),
                                ),
                              );
                          },
                          icon: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Icon(
                              state.reminders.contains(movie.id)
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              key: ValueKey(state.reminders.contains(movie.id)),
                              size: 20,
                              color: state.reminders.contains(movie.id)
                                  ? AppColors.gold
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              comingSoon
                  ? tr('Releasing {0}', [fmtDate(movie.releaseDate)])
                  : '${tr(movie.language)} • ${movie.certificate}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: comingSoon ? AppColors.gold : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinemaCard extends StatelessWidget {
  final Cinema? cinema;
  const _CinemaCard({required this.cinema});

  @override
  Widget build(BuildContext context) {
    final c = cinema;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [AppColors.tint, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.theaters_rounded, color: AppColors.primary),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c == null
                        ? tr('Pick your favourite cinema')
                        : 'Parda ${c.name}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 2),
                  Text(
                    c == null
                        ? tr('See its showtimes first, every time')
                        : tr('Your cinema • {0}', [c.city]),
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (c == null)
              TextButton(
                onPressed: () => showCinemaPicker(context),
                child: Text(tr('Choose')),
              )
            else
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: Size(40, 40)),
                onPressed: () => Navigator.of(
                  context,
                ).push(appRoute(CinemaDetailScreen(cinema: c))),
                child: Text(tr('Showtimes')),
              ),
          ],
        ),
      ),
    );
  }
}

class _OffersRow extends StatelessWidget {
  const _OffersRow();

  @override
  Widget build(BuildContext context) {
    final offers = repo.offers();
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        separatorBuilder: (_, _) => SizedBox(width: 12),
        itemBuilder: (context, i) {
          final o = offers[i];
          return FadeSlideIn(
            index: i,
            from: Offset(0.25, 0),
            child: PressableScale(
              onTap: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: o.code));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('Code {0} copied — apply it at checkout', [o.code]),
                      ),
                    ),
                  );
              },
              child: Container(
                width: 260,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: o.colors),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -16,
                      child: Floating(
                        amplitude: 4,
                        child: Icon(
                          o.icon,
                          size: 90,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(o.title),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          tr(o.subtitle),
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                o.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
