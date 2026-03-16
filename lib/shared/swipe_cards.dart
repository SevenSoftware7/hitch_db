import 'package:flutter/material.dart';
import 'package:hitch_db/theme/app_semantic_colors.dart';

class SwipeCards<T extends Widget> extends StatefulWidget {
  final Map<Key, T> children;
  final bool useButtons;
  final void Function(T item)? onSwipeLeft;
  final void Function(T item)? onSwipeRight;
  final void Function(T item)? onSwipeUp;

  const SwipeCards({super.key, required this.children, this.useButtons = false, this.onSwipeLeft, this.onSwipeRight, this.onSwipeUp});

  @override
  State<SwipeCards<T>> createState() => _SwipeCardsState<T>();
}

enum SwipeDirection {
  left,
  right,
  up,
}

class _SwipeCardsState<T extends Widget> extends State<SwipeCards<T>> {
  late final Map<Key, T> children;
  late final bool useButtons;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    children = widget.children;
    useButtons = widget.useButtons;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            "No more items",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return _buildSwipeCardScaffold();
  }

  Scaffold _buildSwipeCardScaffold() {
    return Scaffold(
      body: Center(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (var entry in children.entries)
            Center(
              child: _buildSwipeCard(entry.key, children.keys.toList().indexOf(entry.key), entry.value)
            )
          ].reversed.toList(),
        ),
      ),
      bottomSheet: useButtons
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Ink(
              decoration: ShapeDecoration(
                shape: const CircleBorder(),
                color: AppSemanticColors.of(context).dislike,
              ),
              child: IconButton(
                onPressed: () => {
                  _swipeUp(children.keys.toList()[currentIndex], SwipeDirection.left)
                },
                icon: const Icon(Icons.thumb_down),
                color: AppSemanticColors.of(context).onDislike,
              ),
            ),
            const SizedBox(width: 16),
            Ink(
              decoration: ShapeDecoration(
                shape: const CircleBorder(),
                color: AppSemanticColors.of(context).alreadyWatched,
              ),
              child: IconButton(
                onPressed: () => {
                  _swipeUp(children.keys.toList()[currentIndex], SwipeDirection.up)
                },
                icon: const Icon(Icons.visibility),
                color: AppSemanticColors.of(context).onAlreadyWatched,
              ),
            ),
            const SizedBox(width: 16),
            Ink(
              decoration: ShapeDecoration(
                shape: const CircleBorder(),
                color: AppSemanticColors.of(context).like,
              ),
              child: IconButton(
                onPressed: () => {
                  _swipeUp(children.keys.toList()[currentIndex], SwipeDirection.right)
                },
                icon: const Icon(Icons.thumb_up),
                color: AppSemanticColors.of(context).onLike,
              ),
            ),
          ],
        )
        : null,
    );
  }

  Widget _buildSwipeCard(Key key, int index, Widget child) {
    final semanticColors = AppSemanticColors.of(context);

    return Transform.translate(
      offset: Offset(0, -_calculateOffset(index)),
      child: Transform.scale(
        scale: _calculateScale(index),
        child: SizedBox(
          height: 500,
          width: 280,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Dismissible(
              key: key,
              direction: DismissDirection.up,
              onDismissed: (direction) {
                _swipeUp(key, SwipeDirection.up);
              },
              background: Container(
                color: semanticColors.alreadyWatched,
                alignment: Alignment.center,
                child: Icon(
                  Icons.visibility,
                  color: semanticColors.onAlreadyWatched,
                  size: 48,
                ),
              ),
              child: Dismissible(
                key: key,
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  _swipeUp(
                    key,
                    direction == DismissDirection.startToEnd
                      ? SwipeDirection.right
                      : SwipeDirection.left
                  );
                },
                background: Container(
                  color: semanticColors.like,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.thumb_up,
                    color: semanticColors.onLike,
                    size: 48,
                  ),
                ),
                secondaryBackground: Container(
                  color: semanticColors.dislike,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.thumb_down,
                    color: semanticColors.onDislike,
                    size: 48,
                  ),
                ),
                child: child,
              ),
            ),
          )
        )
      )
    );
  }

  void _swipeUp(Key key, SwipeDirection direction) {
    T item = children.values.toList()[currentIndex];

    switch (direction) {
      case SwipeDirection.up:
        widget.onSwipeUp?.call(item);
        break;
      case SwipeDirection.left:
        widget.onSwipeLeft?.call(item);
        break;
      case SwipeDirection.right:
        widget.onSwipeRight?.call(item);
        break;
    }

    setState(() {
      children.remove(key);
    });
  }

  double _calculateOffset(int index) =>
    switch (index) {
      0 => 0,
      1 => 35,
      2 => 80,
      _ => 122.5,
    };
  double _calculateScale(int index) =>
    switch (index) {
      0 => 1,
      1 => 0.90,
      2 => 0.75,
      _ => 0.60,
    };
}