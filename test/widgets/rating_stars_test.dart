import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitch_db/theme/app_semantic_colors.dart';
import 'package:hitch_db/widgets/rating_stars.dart';

void main() {
  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
    return ThemeData(
      colorScheme: scheme,
      extensions: [AppSemanticColors.fromScheme(scheme)],
    );
  }

  Widget _wrap(Widget child) {
    return MaterialApp(
      theme: _theme(),
      home: Scaffold(body: child),
    );
  }

  group('RatingStars', () {
    testWidgets('renders full, half, and empty stars for mid ratings', (tester) async {
      await tester.pumpWidget(_wrap(const RatingStars(rating: 7.0)));

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('clamps ratings above max to five full stars', (tester) async {
      await tester.pumpWidget(_wrap(const RatingStars(rating: 12.0)));

      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });
  });
}
