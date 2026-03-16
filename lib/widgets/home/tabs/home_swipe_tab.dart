import 'package:flutter/material.dart';

import 'package:hitch_db/models/movie.dart';
import 'package:hitch_db/widgets/movie/movie_preview.dart';
import 'package:hitch_db/services/movie_service.dart';
import 'package:hitch_db/shared/swipe_cards.dart';

class HomeSwipeTab extends StatelessWidget {
  const HomeSwipeTab({
    required this.movieService,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    super.key,
  });

  final MovieService movieService;
  final void Function(Movie movie) onSwipeLeft;
  final Future<void> Function(Movie movie) onSwipeRight;
  final Future<void> Function(Movie movie) onSwipeUp;

  @override
  Widget build(BuildContext context) {
    if (movieService.isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return SwipeCards<MoviePreview>(
      children: _buildMoviePreviewDict(movieService.swiperMovies),
      useButtons: false,
      onSwipeLeft: (item) => onSwipeLeft(item.movie),
      onSwipeRight: (item) => onSwipeRight(item.movie),
      onSwipeUp: (item) => onSwipeUp(item.movie),
    );
  }

  Map<Key, MoviePreview> _buildMoviePreviewDict(List<Movie> movies) {
    return movies
        .map((movie) => MapEntry(Key(movie.title), MoviePreview(movie: movie)))
        .fold<Map<Key, MoviePreview>>(
          {},
          (prev, entry) => {...prev, entry.key: entry.value},
        );
  }
}
