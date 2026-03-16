import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:hitch_db/models/movie.dart';
import 'package:hitch_db/models/profile_models.dart';
import 'package:hitch_db/services/auth_session.dart';
import 'package:hitch_db/services/movie_service.dart';
import 'movie_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movieService = context.watch<MovieService>();
    final theme = Theme.of(context);
    final profile = movieService.profile;

    if (movieService.isLoadingProfile && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: movieService.refreshProfileData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeaderCard(profile: profile),
          const SizedBox(height: 16),
          _ProfileStatsRow(movieService: movieService),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Profile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _showEditPseudoDialog(context, movieService),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit pseudo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use the profile tab to manage your saved movies and lists synced with the HitchDB backend.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (movieService.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      movieService.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Favorites',
            actionLabel: movieService.favorites.isEmpty ? null : 'Clear hints',
            onAction: null,
            child: movieService.favorites.isEmpty
                ? const _EmptyState(
                    message: 'Swipe right on a movie to save it here.',
                  )
                : Column(
                    children: movieService.favorites
                        .map(
                          (entry) => _PosterListTile(
                            title: entry.movie.title,
                            subtitle: _formatDate(
                              entry.addedAt,
                              fallback: 'Saved recently',
                            ),
                            posterUrl: entry.movie.posterUrl,
                            onTap: () => MovieDetailScreen.pushNavigation(
                              context,
                              entry.movie,
                            ),
                            trailing: IconButton(
                              onPressed: () =>
                                _removeFavorite(context, movieService, entry.movie),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Watch later',
            child: movieService.watchLaterMovies.isEmpty
                ? const _EmptyState(
                    message: 'Swipe right on a movie to add it to watch later.',
                  )
                : Column(
                    children: movieService.watchLaterMovies
                        .map(
                          (entry) => _PosterListTile(
                            title: entry.movie.title,
                            subtitle: _formatDate(
                              entry.addedAt,
                              fallback: 'Saved recently',
                            ),
                            posterUrl: entry.movie.posterUrl,
                            onTap: () => MovieDetailScreen.pushNavigation(
                              context,
                              entry.movie,
                            ),
                            trailing: IconButton(
                              onPressed: () => _removeWatchLater(
                                context,
                                movieService,
                                entry,
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Watched',
            child: movieService.watchedMovies.isEmpty
                ? const _EmptyState(
                    message: 'Swipe up on a movie to mark it as watched.',
                  )
                : Column(
                    children: movieService.watchedMovies
                        .map(
                          (entry) => _PosterListTile(
                            title: entry.movie.title,
                            subtitle: [
                              entry.liked ? 'Liked' : 'Watched',
                              if (entry.rating != null)
                                'Rating ${entry.rating}/10',
                              _formatDate(
                                entry.watchedAt,
                                fallback: 'Recently watched',
                              ),
                            ].join(' • '),
                            posterUrl: entry.movie.posterUrl,
                            onTap: () => MovieDetailScreen.pushNavigation(
                              context,
                              entry.movie,
                            ),
                            trailing: IconButton(
                              onPressed: () =>
                                _removeWatched(context, movieService, entry.movie),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Movie lists',
            actionLabel: 'New list',
            onAction: () => _showCreateListDialog(context, movieService),
            child: movieService.movieLists.isEmpty
                ? const _EmptyState(
                    message: 'Create a list to start organizing movies.',
                  )
                : Column(
                    children: movieService.movieLists
                        .map(
                          (list) => _MovieListCard(
                            list: list,
                            onDelete: () =>
                                _deleteMovieList(context, movieService, list),
                            onRemoveMovie: (itemId) => _removeMovieFromList(
                              context,
                              movieService,
                              list.id,
                              itemId,
                            ),
                            onOpenMovie: (movie) => MovieDetailScreen.pushNavigation(
                              context,
                              movie,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              await context.read<AuthSession>().logout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPseudoDialog(
    BuildContext context,
    MovieService movieService,
  ) async {
    final controller = TextEditingController(
      text: movieService.profile?.pseudo ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit pseudo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Pseudo'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await movieService.updatePseudo(controller.text);
      messenger.showSnackBar(const SnackBar(content: Text('Pseudo updated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showCreateListDialog(
    BuildContext context,
    MovieService movieService,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) {
      return;
    }

    try {
      await movieService.createMovieList(
        name: nameController.text,
        description: descriptionController.text,
      );
      messenger.showSnackBar(const SnackBar(content: Text('List created.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeFavorite(
    BuildContext context,
    MovieService movieService,
    Movie movie,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await movieService.removeFavorite(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeWatched(
    BuildContext context,
    MovieService movieService,
    Movie movie,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await movieService.removeWatchedMovie(movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeWatchLater(
    BuildContext context,
    MovieService movieService,
    WatchLaterMovieEntry entry,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await movieService.removeFromWatchLater(entry.movie);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteMovieList(
    BuildContext context,
    MovieService movieService,
    UserMovieList list,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await movieService.deleteMovieList(list.id);
      messenger.showSnackBar(const SnackBar(content: Text('List deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeMovieFromList(
    BuildContext context,
    MovieService movieService,
    int listId,
    int itemId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await movieService.removeMovieFromList(listId, itemId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Movie removed from list.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  static String _formatDate(DateTime? date, {required String fallback}) {
    if (date == null) {
      return fallback;
    }
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                (profile?.displayName.isNotEmpty == true)
                    ? profile!.displayName.characters.first.toUpperCase()
                    : '?',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'Loading profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.email ?? 'Fetching account details...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.movieService});

  final MovieService movieService;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 4,
      children: [
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Favorites',
            value: '${movieService.favorites.length}',
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Watch later',
            value: '${movieService.watchLaterMovies.length}',
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Watched',
            value: '${movieService.watchedMovies.length}',
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Lists',
            value: '${movieService.movieLists.length}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PosterListTile extends StatelessWidget {
  const _PosterListTile({
    required this.title,
    required this.subtitle,
    required this.posterUrl,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String posterUrl;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl.isEmpty
              ? Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.movie_outlined),
                )
              : CachedNetworkImage(
                  imageUrl: posterUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.movie_outlined),
                  ),
                ),
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}

class _MovieListCard extends StatelessWidget {
  const _MovieListCard({
    required this.list,
    required this.onDelete,
    required this.onRemoveMovie,
    this.onOpenMovie,
  });

  final UserMovieList list;
  final VoidCallback onDelete;
  final ValueChanged<int> onRemoveMovie;
  final ValueChanged<Movie>? onOpenMovie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (list.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(list.description),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${list.items.length} movies',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (list.items.isEmpty)
              const Text('No movies in this list yet.')
            else
              Column(
                children: list.items
                    .map(
                      (item) => _PosterListTile(
                        title: item.movie.title,
                        subtitle: 'Saved to this list',
                        posterUrl: item.movie.posterUrl,
                        onTap: onOpenMovie != null
                            ? () => onOpenMovie!(item.movie)
                            : null,
                        trailing: IconButton(
                          onPressed: () => onRemoveMovie(item.id),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
