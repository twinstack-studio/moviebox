import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'seat_screen.dart';
import '../l10n.dart';
import '../services/analytics.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  /// Matches the poster's Hero tag on the screen we came from, so the poster
  /// flies into place.
  final String? heroTag;
  const MovieDetailScreen({super.key, required this.movie, this.heroTag});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  DateTime _date = dayOnly(DateTime.now());
  String? _cinemaId;
  bool _cinemaInit = false;

  Movie get movie => widget.movie;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cinemaInit) {
      Analytics.log('view_movie', {'movie': movie.title});
      _cinemaId = AppScope.read(context).cinemaId;
      _cinemaInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cinemas = MockCinemaRepository.cinemasIn(state.city);
    if (_cinemaId != null && !cinemas.any((c) => c.id == _cinemaId)) {
      _cinemaId = null;
    }
    final saved = state.isWatchlisted(movie.id);

    Widget poster = Container(
      width: 180,
      height: 262,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: PosterArt(movie: movie, radius: 18),
    );
    if (widget.heroTag != null) {
      poster = Hero(
        tag: widget.heroTag!,
        child: Material(type: MaterialType.transparency, child: poster),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 400,
            backgroundColor: AppColors.bg,
            leading: Padding(
              padding: EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    tooltip: saved
                        ? tr('Remove from watchlist')
                        : tr('Add to watchlist'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      state.toggleWatchlist(movie.id);
                    },
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: 350),
                      transitionBuilder: (c, a) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: a,
                          curve: Curves.elasticOut,
                        ),
                        child: c,
                      ),
                      child: Icon(
                        saved ? Icons.favorite_rounded : Icons.favorite_border,
                        key: ValueKey(saved),
                        color: saved ? AppColors.primary : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  BlurredBackdrop(movie: movie),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), AppColors.bg],
                        stops: [0.2, 1],
                      ),
                    ),
                  ),
                  Align(alignment: Alignment(0, 0.55), child: poster),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _Info(movie: movie)),
          if (movie.nowShowing) ...[
            SliverToBoxAdapter(child: SectionHeader(tr('Showtimes'))),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      tr('Showing in {0}', [state.city]),
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () => showCityPicker(context),
                      child: Text(tr('Change city')),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: DateStrip(
                selected: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  children: [
                    _cinemaChip(tr('All cinemas'), null),
                    for (final c in cinemas) _cinemaChip(c.name, c.id),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AsyncView<List<Showtime>>(
                key: ValueKey('${state.city}|$_date|$_cinemaId'),
                load: () => repo.showtimes(
                  date: _date,
                  movieId: movie.id,
                  cinemaId: _cinemaId,
                  city: state.city,
                ),
                loading: ListSkeleton(count: 2, height: 140),
                isEmpty: (l) => l.isEmpty,
                empty: EmptyState(
                  icon: Icons.event_busy_outlined,
                  message: tr(
                    'No shows left for this date here.\nTry another day or cinema.',
                  ),
                ),
                builder: (context, shows) => _ShowtimeGroups(
                  movie: movie,
                  shows: shows,
                  cinemas: cinemas,
                ),
              ),
            ),
          ] else
            SliverToBoxAdapter(child: _ComingSoonCard(movie: movie)),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _cinemaChip(String label, String? id) {
    final selected = _cinemaId == id;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: appTextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _cinemaId = id),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final Movie movie;
  const _Info({required this.movie});

  @override
  Widget build(BuildContext context) {
    var i = 0;
    Widget stagger(Widget child) => FadeSlideIn(index: i++, child: child);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stagger(
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        movie.genres.map(tr).join(' • '),
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (movie.rating != null) ...[
                  SizedBox(width: 12),
                  RatingRing(rating: movie.rating!),
                ],
              ],
            ),
          ),
          SizedBox(height: 14),
          stagger(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(movie.certificate, icon: Icons.shield_outlined),
                InfoChip(movie.durationLabel, icon: Icons.schedule),
                InfoChip(tr(movie.language), icon: Icons.translate),
                for (final f in movie.formats)
                  InfoChip(
                    f,
                    icon: Icons.videocam_outlined,
                    color: f == '3D' ? AppColors.gold : null,
                  ),
              ],
            ),
          ),
          SizedBox(height: 18),
          stagger(_ExpandableText(movie.synopsis)),
          SizedBox(height: 16),
          stagger(_kv(tr('Director'), movie.director)),
          SizedBox(height: 6),
          stagger(_kv(tr('Cast'), movie.cast.join(', '))),
          SizedBox(height: 16),
          stagger(
            OutlinedButton.icon(
              onPressed: () => openLink(
                context,
                Uri.parse(
                  'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${movie.title} official trailer')}',
                ),
              ),
              icon: Icon(Icons.play_circle_outline, color: AppColors.primary),
              label: Text(tr('Watch trailer')),
            ),
          ),
        ],
      ),
    );
  }

  // Text.rich (not RichText) so it inherits the app font.
  Widget _kv(String k, String v) => Text.rich(
    TextSpan(
      style: TextStyle(fontSize: 14, height: 1.4),
      children: [
        TextSpan(
          text: '$k  ',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
        TextSpan(
          text: v,
          style: TextStyle(color: AppColors.text),
        ),
      ],
    ),
  );
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText(this.text);

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedSize(
        duration: Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Text(
          widget.text,
          maxLines: _open ? null : 3,
          overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSoft, height: 1.55),
        ),
      ),
    );
  }
}

class _ShowtimeGroups extends StatelessWidget {
  final Movie movie;
  final List<Showtime> shows;
  final List<Cinema> cinemas;
  const _ShowtimeGroups({
    required this.movie,
    required this.shows,
    required this.cinemas,
  });

  @override
  Widget build(BuildContext context) {
    final withShows = cinemas
        .where((c) => shows.any((s) => s.cinemaId == c.id))
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          for (final (i, c) in withShows.indexed)
            FadeSlideIn(
              index: i,
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.theaters_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Parda ${c.name}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 28, top: 2),
                          child: Text(
                            c.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final s in shows.where(
                              (s) => s.cinemaId == c.id,
                            ))
                              ShowtimeChip(
                                showtime: s,
                                durationMin: movie.durationMin,
                                onTap: () => startBooking(
                                  context,
                                  movie: movie,
                                  cinema: c,
                                  showtime: s,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ShowtimeChip extends StatelessWidget {
  final Showtime showtime;
  final int durationMin;
  final VoidCallback onTap;
  const ShowtimeChip({
    super.key,
    required this.showtime,
    required this.durationMin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = showtime;
    final end = s.start.add(Duration(minutes: durationMin));
    final is3d = s.format == '3D';
    final occ = MockCinemaRepository.occupancyFor(s);
    final (label, color) = occ > 0.42
        ? (tr('Almost full'), AppColors.primary)
        : occ > 0.3
        ? (tr('Filling fast'), AppColors.warning)
        : (tr('Available'), AppColors.success);
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: is3d
                ? AppColors.gold.withValues(alpha: 0.6)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              fmtTime(s.start),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            SizedBox(height: 2),
            Text(
              s.isLateNight
                  ? tr('Late night • {0}', [DateFormat('EEE').format(s.start)])
                  : tr('{0} • ends {1}', [s.format, fmtTime(end)]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: s.isLateNight || is3d ? AppColors.gold : AppColors.muted,
              ),
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  const DateStrip({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7,
        separatorBuilder: (_, _) => SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = today.add(Duration(days: i));
          final sel = d == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(d);
            },
            child: AnimatedScale(
              scale: sel ? 1.06 : 1,
              duration: Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: 60,
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      i == 0
                          ? tr('Today')
                          : i == 1
                          ? tr('Tmrw')
                          : DateFormat('EEE').format(d),
                      style: TextStyle(
                        fontSize: 12,
                        color: sel ? Colors.white : AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(d),
                      style: TextStyle(
                        fontSize: 11,
                        color: sel ? Colors.white70 : AppColors.muted,
                      ),
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

class _ComingSoonCard extends StatelessWidget {
  final Movie movie;
  const _ComingSoonCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final on = state.reminders.contains(movie.id);
    final days = dayOnly(
      movie.releaseDate,
    ).difference(dayOnly(DateTime.now())).inDays;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: FadeSlideIn(
        index: 3,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Floating(
                  child: Icon(
                    Icons.event_rounded,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  tr('Releasing {0}', [fmtDateLong(movie.releaseDate)]),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                if (days > 0) ...[
                  SizedBox(height: 6),
                  CountUp(
                    value: days,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                  Text(
                    tr('days to go'),
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
                SizedBox(height: 10),
                Text(
                  tr('Bookings open closer to release. Get notified first.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: on
                      ? OutlinedButton.icon(
                          onPressed: () => state.toggleReminder(movie.id),
                          icon: Icon(
                            Icons.notifications_active,
                            color: AppColors.gold,
                          ),
                          label: Text(tr('Reminder set')),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            state.toggleReminder(movie.id);
                          },
                          icon: Icon(Icons.notifications_none),
                          label: Text(tr('Remind me')),
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
