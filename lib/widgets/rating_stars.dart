import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    // Convert rating from 0-10 scale to 0-5 stars
    final stars = (rating / 2).clamp(0.0, 5.0);
    final fullStars = stars.floor();
    final hasHalfStar = (stars - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(
            Icons.star,
            color: Colors.amber,
            size: size,
          );
        } else if (index == fullStars && hasHalfStar) {
          return Icon(
            Icons.star_half,
            color: Colors.amber,
            size: size,
          );
        } else {
          return Icon(
            Icons.star_border,
            color: Colors.amber,
            size: size,
          );
        }
      }),
    );
  }
}
