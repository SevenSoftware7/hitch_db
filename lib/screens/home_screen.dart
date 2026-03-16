import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:hitch_db/models/movie.dart';
import 'package:hitch_db/screens/movie_detail_screen.dart';
import 'package:hitch_db/screens/profile_screen.dart';
import 'package:hitch_db/screens/movie_preview.dart';
import 'package:hitch_db/screens/search_screen.dart';
import 'package:hitch_db/screens/settings_screen.dart';
import 'package:hitch_db/widgets/movie_card.dart';
import 'package:hitch_db/widgets/swipe_cards.dart';
import 'package:hitch_db/services/movie_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieService>().initialize(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movieService = context.watch<MovieService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        title: const Text('Hitch DB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildExploreTab(movieService),
          _buildSwipeWidget(movieService),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Explore', icon: Icon(Icons.search)),
          Tab(text: 'Swipe', icon: Icon(Icons.amp_stories_rounded)),
          Tab(text: 'Profile', icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  Widget _buildExploreTab(MovieService movieService) {
    if (movieService.isInitializing && movieService.cachedMovies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (movieService.errorMessage != null &&
        movieService.cachedMovies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(movieService.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => movieService.initialize(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          movieService.getPopularMovies(),
          movieService.refreshWatchLaterMovies(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildWatchLaterSection(movieService)),
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return MovieCard(movie: movieService.cachedMovies[index]);
              }, childCount: movieService.cachedMovies.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchLaterSection(MovieService movieService) {
    final watchLater = movieService.watchLaterMovies;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watch later',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: movieService.isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : watchLater.isEmpty
                ? Center(
                    child: Text(
                      'Swipe right in Swipe tab to fill your watch later list.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: watchLater.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final entry = watchLater[index];
                      return SizedBox(
                        width: 128,
                        child: InkWell(
                          onTap: () => MovieDetailScreen.pushNavigation(context, entry.movie),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: entry.movie.posterUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: entry.movie.posterUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                child: const Icon(Icons.movie),
                                              ),
                                        )
                                      : Container(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.movie),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    8,
                                    6,
                                  ),
                                  child: Text(
                                    entry.movie.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      await movieService.removeFromWatchLater(
                                        entry.movie,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.bookmark_remove_outlined,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeWidget(MovieService movieService) {
    if (movieService.isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    return SwipeCards<MoviePreview>(
      children: _buildMoviePreviewDict(movieService.swiperMovies),
      useButtons: false,
      onSwipeLeft: (item) => _onSkip(item.movie),
      onSwipeRight: (item) => _onWatchLater(item.movie),
      onSwipeUp: (item) => _onAlreadyWatched(item.movie),
    );
  }

  Map<Key, MoviePreview> _buildMoviePreviewDict(List<Movie> movies) => movies
      .map((movie) => MapEntry(Key(movie.title), MoviePreview(movie: movie)))
      .fold<Map<Key, MoviePreview>>(
        {},
        (prev, entry) => {...prev, entry.key: entry.value},
      );

  void _onSkip(Movie movie) {
    if (!mounted) {
      return;
    }
  }

  Future<void> _onWatchLater(Movie movie) async {
    final messenger = ScaffoldMessenger.of(context);
    final movieService = context.read<MovieService>();

    try {
      await movieService.addToWatchLater(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to add ${movie.title} to watch later.')));
      return;
    }
  }

  Future<void> _onAlreadyWatched(Movie movie) async {
    final messenger = ScaffoldMessenger.of(context);
    final movieService = context.read<MovieService>();

    try {
      await movieService.markWatched(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to mark ${movie.title} as watched.')));
      return;
    }
  }
}
