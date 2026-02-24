import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hitch_db/screens/movie_detail_screen.dart';
import 'package:hitch_db/widgets/rating_stars.dart';
import 'package:intl/intl.dart';
import '../models/movie.dart';

class MoviePreviewScreen extends StatelessWidget {
  final Movie movie;

  const MoviePreviewScreen({super.key, required Movie movie}) : this.movie = movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Backdrop
          SliverAppBar(
            expandedHeight: 512,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: _createMovieInfoWidget(context)
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: movie.posterUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, size: 80),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
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
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: _createMovieOverviewWidget(context)
            )
          ),
        ],
      ),
    );
  }

  Widget _createMovieOverviewWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Column(
        children: [
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
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      )
    );
  }

  Widget _createMovieInfoWidget(BuildContext context) {
    return Column(
      children: [
        Text(
          movie.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
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
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                "Rating: ${movie.adult ? '18+' : 'PG-13'}",
                style: TextStyle(
                  fontSize: 16,
                ),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ),
                  Text(
                    '${NumberFormat('#,###').format(movie.voteCount)} votes',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ]
              ),
            ],
          ),
        ),
      ],
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
