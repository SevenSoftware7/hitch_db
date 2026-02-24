import 'package:flutter/material.dart';

import 'package:hitch_db/screens/movie_preview_screen.dart';
import 'package:hitch_db/widgets/swipeable.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum PageStatus { none, searching, settings }

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _movies = [];
  List<Movie> _searchResults = [];

  bool _isLoading = false;
  PageStatus _state = PageStatus.none;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMovies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final topRated = await _movieService.getTopRatedMovies();

      setState(() {
        _movies = topRated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _state = PageStatus.none;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _state = PageStatus.searching;
    });

    try {
      final results = await _movieService.searchMovies(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
          IconButton(
            icon: Icon(_state == PageStatus.searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_state == PageStatus.searching) {
                  _state = PageStatus.none;
                  _searchController.clear();
                  _searchResults = [];
                } else {
                  _state = PageStatus.searching;
                }
              });
            },
          ),
        title: switch (_state) {
          PageStatus.searching => TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search movies...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: _searchMovies,
            ),
          _ => const Text('Hitch DB'),
        },
        actions: [
          IconButton(
            icon: Icon(_state == PageStatus.settings ? Icons.close : Icons.settings),
            onPressed: () {
              setState(() {
                if (_state == PageStatus.settings) {
                  _state = PageStatus.none;
                } else {
                  _state = PageStatus.settings;
                }
              });
            },
          ),
        ]
      ),
      body: switch (_state) {
        PageStatus.searching => _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading movies',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMovies,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildSearchResults(),
        PageStatus.settings => Text("Test"),
        _ => TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              Container(child: _buildMovieGrid(_movies)),
              Container(child: _buildSwipeWidget(_movies)),
              Container(),
            ],
          )
      },
      bottomNavigationBar: _state == PageStatus.none
        ? TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Explore', icon: Icon(Icons.search)),
              Tab(text: 'Swipe', icon: Icon(Icons.amp_stories_rounded)),
              Tab(text: 'Profile', icon: Icon(Icons.person)),
            ],
          )
        : null
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text('No movies found'),
      );
    }

    return _buildMovieGrid(_searchResults);
  }

  Widget _buildMovieGrid(List<Movie> movies) {
    if (movies.isEmpty) {
      return const Center(
        child: Text('No movies available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovies,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return MovieCard(movie: movies[index]);
        },
      ),
    );
  }


  Widget _buildSwipeWidget(List<Movie> movies) {
    return SwipeCards<MoviePreviewScreen>(
      children:  movies.map(
        (movie) => MapEntry(Key(movie.title), MoviePreviewScreen(movie: movie)))
        .fold<Map<Key, MoviePreviewScreen>>({}, (prev, entry) => {...prev, entry.key: entry.value}),
      useButtons: false,
      onSwipeLeft: (item) => _onDislike(item.movie),
      onSwipeRight: (item) => _onLike(item.movie),
    );
  }

  void _onDislike(Movie movie) {
    // Handle left swipe (dislike)
    print('Disliked: ${movie.title}');
  }

  void _onLike(Movie movie) {
    // Handle right swipe (like)
    print('Liked: ${movie.title}');
  }
}
