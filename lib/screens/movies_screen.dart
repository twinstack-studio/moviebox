import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import '../l10n.dart';

/// 0 = Now Showing, 1 = Coming Soon. Lets Home's "See all" jump to a tab.
final moviesTabIndex = ValueNotifier<int>(0);

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: moviesTabIndex.value,
  );
  final _search = TextEditingController();
  String _query = '';
  String _genre = 'All';

  @override
  void initState() {
    super.initState();
    moviesTabIndex.addListener(_syncTab);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) moviesTabIndex.value = _tabs.index;
    });
  }

  void _syncTab() {
    if (_tabs.index != moviesTabIndex.value) {
      _tabs.animateTo(moviesTabIndex.value);
    }
  }

  @override
  void dispose() {
    moviesTabIndex.removeListener(_syncTab);
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Movie> _filter(List<Movie> list) {
    final q = _query.trim().toLowerCase();
    return list.where((m) {
      final matchQ =
          q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.cast.any((c) => c.toLowerCase().contains(q)) ||
          m.language.toLowerCase().contains(q);
      final matchG = _genre == 'All' || m.genres.contains(_genre);
      return matchQ && matchG;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Movies')),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.text,
          unselectedLabelColor: AppColors.muted,
          labelStyle: appTextStyle(fontWeight: FontWeight.w700),
          dividerColor: AppColors.border,
          tabs: [
            Tab(text: tr('Now Showing')),
            Tab(text: tr('Coming Soon')),
          ],
        ),
      ),
      body: AsyncView<List<Movie>>(
        load: repo.movies,
        loading: GridSkeleton(),
        builder: (context, movies) {
          final genres = <String>{'All', ...movies.expand((m) => m.genres)};
          final showing = _filter(movies.where((m) => m.nowShowing).toList());
          final soon = _filter(movies.where((m) => !m.nowShowing).toList());
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: tr('Search movies, actors, languages'),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final g in genres)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tr(g)),
                          selected: _genre == g,
                          showCheckmark: false,
                          labelStyle: appTextStyle(
                            color: _genre == g ? Colors.white : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _genre = g),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _Grid(
                      key: ValueKey('now|$_genre|$_query'),
                      movies: showing,
                      heroPrefix: 'grid-now',
                    ),
                    _Grid(
                      key: ValueKey('soon|$_genre|$_query'),
                      movies: soon,
                      comingSoon: true,
                      heroPrefix: 'grid-soon',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Movie> movies;
  final bool comingSoon;
  final String heroPrefix;
  const _Grid({
    super.key,
    required this.movies,
    required this.heroPrefix,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return EmptyState(
        message: tr('No movies match your search.'),
        icon: Icons.search_off,
      );
    }
    return MovieGrid(
      movies: movies,
      comingSoon: comingSoon,
      heroPrefix: heroPrefix,
    );
  }
}

class MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final bool comingSoon;
  final String heroPrefix;
  const MovieGrid({
    super.key,
    required this.movies,
    this.comingSoon = false,
    this.heroPrefix = 'grid',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 700 ? 4 : (c.maxWidth > 500 ? 3 : 2);
        final itemW = (c.maxWidth - 40 - 14 * (cols - 1)) / cols;
        return GridView.builder(
          physics: BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            mainAxisExtent: itemW * 1.45 + 60,
          ),
          itemCount: movies.length,
          itemBuilder: (_, i) => FadeSlideIn(
            index: i,
            child: MovieTile(
              movie: movies[i],
              comingSoon: comingSoon,
              heroTag: '$heroPrefix-${movies[i].id}',
            ),
          ),
        );
      },
    );
  }
}
