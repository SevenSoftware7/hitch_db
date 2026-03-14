import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color rating;
  final Color onRating;
  final Color like;
  final Color onLike;
  final Color dislike;
  final Color onDislike;
  final Color alreadyWatched;
  final Color onAlreadyWatched;

  const AppSemanticColors({
    required this.rating,
    required this.onRating,
    required this.like,
    required this.onLike,
    required this.dislike,
    required this.onDislike,
    required this.alreadyWatched,
    required this.onAlreadyWatched,
  });

  factory AppSemanticColors.fromScheme(ColorScheme colorScheme) {
    return AppSemanticColors(
      rating: colorScheme.secondary,
      onRating: colorScheme.onSecondary,
      like: Colors.green,
      onLike: Colors.white,
      dislike: Colors.red,
      onDislike: Colors.white,
      alreadyWatched: colorScheme.primary,
      onAlreadyWatched: colorScheme.onPrimary,
    );
  }

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>()!;
  }

  @override
  AppSemanticColors copyWith({
    Color? rating,
    Color? onRating,
    Color? like,
    Color? onLike,
    Color? dislike,
    Color? onDislike,
    Color? alreadyWatched,
    Color? onAlreadyWatched,
  }) {
    return AppSemanticColors(
      rating: rating ?? this.rating,
      onRating: onRating ?? this.onRating,
      like: like ?? this.like,
      onLike: onLike ?? this.onLike,
      dislike: dislike ?? this.dislike,
      onDislike: onDislike ?? this.onDislike,
      alreadyWatched: alreadyWatched ?? this.alreadyWatched,
      onAlreadyWatched: onAlreadyWatched ?? this.onAlreadyWatched,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }

    return AppSemanticColors(
      rating: Color.lerp(rating, other.rating, t) ?? rating,
      onRating: Color.lerp(onRating, other.onRating, t) ?? onRating,
      like: Color.lerp(like, other.like, t) ?? like,
      onLike: Color.lerp(onLike, other.onLike, t) ?? onLike,
      dislike: Color.lerp(dislike, other.dislike, t) ?? dislike,
      onDislike: Color.lerp(onDislike, other.onDislike, t) ?? onDislike,
      alreadyWatched: Color.lerp(alreadyWatched, other.alreadyWatched, t) ?? alreadyWatched,
      onAlreadyWatched: Color.lerp(onAlreadyWatched, other.onAlreadyWatched, t) ?? onAlreadyWatched,
    );
  }
}