import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:hitch_db/widgets/movie/movie_detail_screen.dart';
import 'package:hitch_db/services/movie_service.dart';
import 'package:hitch_db/widgets/movie/movie_card.dart';

class HomeExploreTab extends StatelessWidget {
  const HomeExploreTab({
    required this.movieService,
    required this.onRetry,
    required this.onRefresh,
    required this.onRemoveFromWatchLater,
    super.key,
  });

  final MovieService movieService;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int movieId) onRemoveFromWatchLater;

  @override
  Widget build(BuildContext context) {
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
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _WatchLaterSection(
              movieService: movieService,
              onRemoveFromWatchLater: onRemoveFromWatchLater,
            ),
          ),
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
}

class _WatchLaterSection extends StatelessWidget {
  const _WatchLaterSection({
    required this.movieService,
    required this.onRemoveFromWatchLater,
  });

  final MovieService movieService;
  final Future<void> Function(int movieId) onRemoveFromWatchLater;

  @override
  Widget build(BuildContext context) {
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
                          onTap: () => MovieDetailScreen.pushNavigation(
                            context,
                            entry.movie,
                          ),
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
                                    onPressed: () =>
                                        onRemoveFromWatchLater(entry.movie.id),
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
}
