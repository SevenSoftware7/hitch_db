import 'package:flutter/material.dart';

import 'package:hitch_db/models/movie.dart';
import 'package:hitch_db/widgets/home/tabs/home_profile_screen.dart';
import 'package:hitch_db/widgets/home/search_screen.dart';
import 'package:hitch_db/widgets/settings/settings_screen.dart';
import 'package:hitch_db/widgets/home/tabs/home_explore_tab.dart';
import 'package:hitch_db/widgets/home/tabs/home_swipe_tab.dart';
import 'package:hitch_db/services/movie_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieService>().initialize(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movieService = context.watch<MovieService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        title: const Text('Hitch DB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HomeExploreTab(
            movieService: movieService,
            onRetry: () => movieService.initialize(forceRefresh: true),
            onRefresh: () async {
              await Future.wait([
                movieService.getPopularMovies(),
                movieService.refreshWatchLaterMovies(),
              ]);
            },
            onRemoveFromWatchLater: (movieId) async {
              Movie? selected;
              for (final entry in movieService.watchLaterMovies) {
                if (entry.movie.id == movieId) {
                  selected = entry.movie;
                  break;
                }
              }
              if (selected == null) {
                return;
              }
              await movieService.removeFromWatchLater(selected);
            },
          ),
          HomeSwipeTab(
            movieService: movieService,
            onSwipeLeft: _onSkip,
            onSwipeRight: _onWatchLater,
            onSwipeUp: _onAlreadyWatched,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Explore', icon: Icon(Icons.search)),
          Tab(text: 'Swipe', icon: Icon(Icons.amp_stories_rounded)),
          Tab(text: 'Profile', icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  void _onSkip(Movie movie) {
    if (!mounted) {
      return;
    }
  }

  Future<void> _onWatchLater(Movie movie) async {
    final messenger = ScaffoldMessenger.of(context);
    final movieService = context.read<MovieService>();

    try {
      await movieService.addToWatchLater(movie);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to add ${movie.title} to watch later.')),
      );
      return;
    }
  }

  Future<void> _onAlreadyWatched(Movie movie) async {
    final messenger = ScaffoldMessenger.of(context);
    final movieService = context.read<MovieService>();

    try {
      await movieService.markWatched(movie);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to mark ${movie.title} as watched.')),
      );
      return;
    }
  }
}
