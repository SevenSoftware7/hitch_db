import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:hitch_db/services/movie_service.dart';

import '../models/movie.dart';
import '../widgets/rating_stars.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  static void pushNavigation(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movie)),
    );
  }

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final movieService = context.watch<MovieService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  movie.backdropUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.backdropUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.movie, size: 80),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.movie, size: 80),
                        ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster and basic info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: movie.posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: movie.posterUrl,
                                width: 120,
                                height: 180,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 120,
                                  height: 180,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 120,
                                  height: 180,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.movie, size: 40),
                                ),
                              )
                            : Container(
                                width: 120,
                                height: 180,
                                color: colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.movie, size: 40),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatReleaseDate(movie.releaseDate),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                RatingStars(rating: movie.voteAverage),
                                const SizedBox(width: 8),
                                Text(
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${NumberFormat('#,###').format(movie.voteCount)} votes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 12,
                            //     vertical: 6,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: Colors.amber.withOpacity(0.2),
                            //     borderRadius: BorderRadius.circular(20),
                            //     border: Border.all(
                            //       color: Colors.amber,
                            //       width: 1,
                            //     ),
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       const Icon(
                            //         Icons.trending_up,
                            //         size: 16,
                            //         color: Colors.amber,
                            //       ),
                            //       const SizedBox(width: 4),
                            //       Text(
                            //         'Popularity: ${movie.popularity.toStringAsFixed(0)}',
                            //         style: const TextStyle(
                            //           fontSize: 12,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Overview section
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview.isNotEmpty
                        ? movie.overview
                        : 'No overview available.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: movieService.isFavorite(movie)
                            ? () => _removeFavorite(context)
                            : () => _saveFavorite(context),
                        icon: Icon(
                          movieService.isFavorite(movie)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        label: Text(
                          movieService.isFavorite(movie) ? 'Unfavorite' : 'Favorite',
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: movieService.isWatched(movie)
                            ? () => _removeWatched(context)
                            : () => _markWatched(context),
                        icon: movieService.isWatched(movie)
                            ? const Icon(Icons.check_circle_outline)
                            : const Icon(Icons.check_circle_outline_outlined),
                        label: Text(
                          movieService.isWatched(movie)
                              ? 'Watched'
                              : 'Mark watched',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: movieService.isWatched(movie)
                            ? null
                            : movieService.isInWatchLater(movie)
                              ? () => _removeFromWatchLater(context)
                              : () => _addToWatchLater(context),
                        icon: movieService.isInWatchLater(movie)
                            ? const Icon(Icons.watch_later)
                            : const Icon(Icons.watch_later_outlined),
                        label: Text(
                          movieService.isInWatchLater(movie)
                              ? 'In Watch Later'
                              : 'Watch Later',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: movieService.movieLists.isEmpty
                            ? null
                            : () => _showAddToListDialog(context, movieService),
                        icon: const Icon(Icons.playlist_add_rounded),
                        label: const Text('Add to list'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Additional info
                  _buildInfoRow(
                    context,
                    'Original Language',
                    movie.originalLanguage.toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Rating',
                    movie.adult ? '18+' : 'PG-13',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  String _formatReleaseDate(String date) {
    if (date.isEmpty) return 'Unknown';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMMM d, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> _saveFavorite(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      context.read<MovieService>().addFavorite(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeFavorite(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<MovieService>().removeFavorite(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addToWatchLater(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<MovieService>().addToWatchLater(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeFromWatchLater(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<MovieService>().removeFromWatchLater(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _markWatched(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<MovieService>().markWatched(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeWatched(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<MovieService>().removeWatchedMovie(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showAddToListDialog(
    BuildContext context,
    MovieService movieService,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final selectedListId = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Add to list')),
            ...movieService.movieLists.map(
              (list) => ListTile(
                leading: const Icon(Icons.list_alt_rounded),
                trailing: movieService.isInMovieList(movie, list.id)
                  ? Icon(Icons.check)
                  : null,
                title: Text(list.name),
                subtitle: Text('${list.items.length} movies'),
                onTap: () => Navigator.of(context).pop(list.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedListId == null) {
      return;
    }

    if (movieService.isInMovieList(movie, selectedListId)) {
      try {
        await movieService.removeMovieFromList(selectedListId, movie);
        messenger.showSnackBar(
          SnackBar(content: Text('${movie.title} removed from your list.')),
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }

    try {
      await movieService.addMovieToList(selectedListId, movie);
      messenger.showSnackBar(
        SnackBar(content: Text('${movie.title} added to your list.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
