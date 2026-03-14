import 'package:flutter/material.dart';

import 'package:hitch_db/screens/movie_preview.dart';
import 'package:hitch_db/screens/search_screen.dart';
import 'package:hitch_db/screens/settings_screen.dart';
import 'package:hitch_db/widgets/movie_card.dart';
import 'package:hitch_db/widgets/swipe_cards.dart';
import 'package:hitch_db/models/movie.dart';
import 'package:hitch_db/services/movie_service.dart';
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
  with SingleTickerProviderStateMixin
{
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            context.watch<MovieService>().cachedMovies.buildMovieGrid(
              onRefresh: context.watch<MovieService>().getPopularMovies,
            ),
            _buildSwipeWidget(context.watch<MovieService>().cachedMovies),
            Container(),
          ],
        ),
      bottomNavigationBar: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explore', icon: Icon(Icons.search)),
            Tab(text: 'Swipe', icon: Icon(Icons.amp_stories_rounded)),
            Tab(text: 'Profile', icon: Icon(Icons.person)),
          ],
        )
    );
  }


  Widget _buildSwipeWidget(List<Movie> movies) {
    return SwipeCards<MoviePreview>(
      children:  _buildMoviePreviewDict(movies),
      useButtons: false,
      onSwipeLeft: (item) => _onDislike(item.movie),
      onSwipeRight: (item) => _onLike(item.movie),
      onSwipeUp: (item) => _onAlreadyWatched(item.movie),
    );
  }

  Map<Key, MoviePreview> _buildMoviePreviewDict(List<Movie> movies) =>
    movies.map(
      (movie) => MapEntry(Key(movie.title), MoviePreview(movie: movie)))
      .fold<Map<Key, MoviePreview>>({}, (prev, entry) => {...prev, entry.key: entry.value});


  void _onDislike(Movie movie) {
    // Handle left swipe (dislike)
    print('Not interested: ${movie.title}');
  }

  void _onLike(Movie movie) {
    // Handle right swipe (like)
    print('Watch later: ${movie.title}');
  }

  void _onAlreadyWatched(Movie movie) {
    // Handle already watched swipe
    print('Already watched: ${movie.title}');
  }
}
