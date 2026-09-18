import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/nav.dart';
import 'movie_detail_screen.dart';
import 'seat_screen.dart';
import '../l10n.dart';

class CinemasScreen extends StatefulWidget {
  const CinemasScreen({super.key});

  @override
  State<CinemasScreen> createState() => _CinemasScreenState();
}

class _CinemasScreenState extends State<CinemasScreen> {
  String? _city; // null = follow the app's selected city

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final city = _city ?? state.city;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Cinemas'))),
      body: AsyncView<List<Cinema>>(
        load: repo.cinemas,
        builder: (context, all) {
          final cities = all.map((c) => c.city).toSet().toList()..sort();
          final list = city == 'All'
              ? all
              : all.where((c) => c.city == city).toList();
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final c in ['All', ...cities])
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: city == c,
                          showCheckmark: false,
                          labelStyle: appTextStyle(
                            color: city == c ? Colors.white : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _city = c),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12),
                  itemBuilder: (_, i) => _CinemaTile(cinema: list[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CinemaTile extends StatelessWidget {
  final Cinema cinema;
  const _CinemaTile({required this.cinema});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final fav = state.cinemaId == cinema.id;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(appRoute(CinemaDetailScreen(cinema: cinema))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.theaters_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parda ${cinema.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          cinema.address,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: fav ? tr('Your cinema') : tr('Set as my cinema'),
                    onPressed: () => state.setCinema(fav ? null : cinema),
                    icon: Icon(
                      fav ? Icons.star_rounded : Icons.star_border,
                      color: fav ? AppColors.gold : AppColors.muted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  InfoChip(tr('{0} screens', [cinema.screens])),
                  for (final a in cinema.amenities) InfoChip(tr(a)),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => openLink(context, telUri(cinema.phone)),
                    icon: Icon(Icons.call_outlined, size: 18),
                    label: Text(tr('Call')),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        openLink(context, mapsUri(cinema.mapsQuery)),
                    icon: Icon(Icons.directions_outlined, size: 18),
                    label: Text(tr('Directions')),
                  ),
                  Spacer(),
                  Text(
                    tr('Showtimes'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CinemaDetailScreen extends StatefulWidget {
  final Cinema cinema;
  const CinemaDetailScreen({super.key, required this.cinema});

  @override
  State<CinemaDetailScreen> createState() => _CinemaDetailScreenState();
}

class _CinemaDetailScreenState extends State<CinemaDetailScreen> {
  DateTime _date = dayOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final c = widget.cinema;
    final state = AppScope.of(context);
    final fav = state.cinemaId == c.id;
    return Scaffold(
      appBar: AppBar(
        title: Text('Parda ${c.name}'),
        actions: [
          IconButton(
            onPressed: () => state.setCinema(fav ? null : c),
            icon: Icon(
              fav ? Icons.star_rounded : Icons.star_border,
              color: fav ? AppColors.gold : null,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text(c.address)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        SizedBox(width: 8),
                        Text(c.phone),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openLink(context, telUri(c.phone)),
                            icon: Icon(Icons.call_outlined),
                            label: Text(tr('Call')),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                openLink(context, mapsUri(c.mapsQuery)),
                            icon: Icon(Icons.directions_outlined),
                            label: Text(tr('Directions')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SectionHeader(tr('Showtimes')),
          DateStrip(
            selected: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          AsyncView<(List<Movie>, List<Showtime>)>(
            key: ValueKey(_date),
            load: () async => (
              await repo.movies(),
              await repo.showtimes(date: _date, cinemaId: c.id),
            ),
            isEmpty: (d) => d.$2.isEmpty,
            empty: EmptyState(
              icon: Icons.event_busy_outlined,
              message: tr('No more shows on this date.\nTry another day.'),
            ),
            builder: (context, data) {
              final (movies, shows) = data;
              return Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    for (final m in movies)
                      if (shows.any((s) => s.movieId == m.id))
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _MovieShows(
                            movie: m,
                            cinema: c,
                            shows: shows
                                .where((s) => s.movieId == m.id)
                                .toList(),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MovieShows extends StatelessWidget {
  final Movie movie;
  final Cinema cinema;
  final List<Showtime> shows;
  const _MovieShows({
    required this.movie,
    required this.cinema,
    required this.shows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.of(
                context,
              ).push(appRoute(MovieDetailScreen(movie: movie))),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    height: 78,
                    child: PosterArt(
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
                          movie.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${movie.certificate} • ${movie.durationLabel} • ${movie.language}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in shows)
                  ShowtimeChip(
                    showtime: s,
                    durationMin: movie.durationMin,
                    onTap: () => startBooking(
                      context,
                      movie: movie,
                      cinema: cinema,
                      showtime: s,
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
