import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hitch_db/widgets/movie/movie_detail_screen.dart';
import 'package:hitch_db/shared/rating_stars.dart';
import 'package:intl/intl.dart';
import '../../models/movie.dart';

class MoviePreview extends StatelessWidget {
  final Movie movie;

  const MoviePreview({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
          fit: StackFit.expand,
          children: [
            movie.posterUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
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
            // Gradient overlay/shadow for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.scrim.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: colorScheme.outline),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => MovieDetailScreen.pushNavigation(context, movie),
                )
              ],
              bottom: _createMovieInfoWidget(context),
            )
          ],
        ),
      );
  }

  PreferredSizeWidget _createMovieInfoWidget(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(180),
      child: Column(
        children: [
          Text(
            movie.title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.center,
              runSpacing: 0,
              runAlignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(
                  _formatReleaseDate(movie.releaseDate),
                  softWrap: true,
                  style: textTheme.bodyLarge,
                ),
                Text(
                  "Rating: ${movie.adult ? '18+' : 'PG-13'}",
                  style: textTheme.bodyLarge,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingStars(rating: movie.voteAverage),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    ),
                    Text(
                      '${NumberFormat('#,###').format(movie.voteCount)} votes',
                      style: textTheme.bodyMedium,
                    ),
                  ]
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReleaseDate(String date) {
    if (date.isEmpty) return 'Unknown';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('d MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
