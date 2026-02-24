import 'package:flutter/material.dart';

class SwipeCards<T extends Widget> extends StatefulWidget {
  final Map<Key, T> children;
  final bool useButtons;
  final void Function(T item)? onSwipeLeft;
  final void Function(T item)? onSwipeRight;

  const SwipeCards({super.key, required this.children, this.useButtons = false, this.onSwipeLeft, this.onSwipeRight});

  @override
  State<SwipeCards<T>> createState() => _SwipeCardsState<T>();
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
    return _buildSwipeCardScaffold();
    // if (!useButtons) return _buildSwipeCardScaffold();
    // return Column(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     _buildSwipeCardScaffold(),
    //     // const SizedBox(height: 16),
    //     // Row(
    //     //   mainAxisAlignment: MainAxisAlignment.center,
    //     //   children: [
    //     //     ElevatedButton(
    //     //       onPressed: () {
    //     //         if (children.isEmpty) return;
    //     //         setState(() {
    //     //           children.remove(children.keys.elementAt(0));
    //     //         });
    //     //       },
    //     //       child: const Icon(Icons.thumb_down),
    //     //     ),
    //     //     const SizedBox(width: 32),
    //     //     ElevatedButton(
    //     //       onPressed: () {
    //     //         if (children.isEmpty) return;
    //     //         setState(() {
    //     //           children.remove(children.keys.elementAt(0));
    //     //         });
    //     //       },
    //     //       child: const Icon(Icons.thumb_up),
    //     //     ),
    //     //   ],
    //     // )
    //   ],
    // );
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
  );
  }

  Widget _buildSwipeCard(Key key, int index, Widget child) {
    return Transform.translate(
      offset: Offset(0, - _calculateOffset(index)),
      child: Transform.scale(
        scale: _calculateScale(index),
        child: SizedBox(
          height: 512,
          width: 275,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Dismissible(
              key: key,
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                setState(() {
                  children.remove(key);
                });
                T item = children.values.toList()[currentIndex];
                if (direction == DismissDirection.endToStart) {
                  widget.onSwipeLeft?.call(item);
                } else if (direction == DismissDirection.startToEnd) {
                  widget.onSwipeRight?.call(item);
                }
              },
              background: Container(
                color: Colors.green,
                alignment: Alignment.center,
                child: Icon(Icons.thumb_up, color: Colors.white, size: 48),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.center,
                child: Icon(Icons.thumb_down, color: Colors.white, size: 48),
              ),
              child: child,
            ),
          )
        )
      )
    );
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