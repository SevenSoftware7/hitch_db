import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class MovieService {
  // TMDB API key - Replace with your own API key from https://www.themoviedb.org/settings/api
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // For demo purposes, if no API key is provided, we'll use mock data
  static const bool _useMockData = _apiKey == 'YOUR_API_KEY_HERE';

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    if (_useMockData) {
      return _getMockMovies();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (_useMockData) {
      return _getMockMovies()
          .where((movie) =>
              movie.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/movie?api_key=$_apiKey&query=$query&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      throw Exception('Error searching movies: $e');
    }
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    if (_useMockData) {
      final movies = _getMockMovies();
      movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      return movies;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/top_rated?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load top rated movies');
      }
    } catch (e) {
      throw Exception('Error fetching top rated movies: $e');
    }
  }

  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    if (_useMockData) {
      return _getMockMovies();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/upcoming?api_key=$_apiKey&page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((movie) => Movie.fromJson(movie)).toList();
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      throw Exception('Error fetching upcoming movies: $e');
    }
  }

  // Mock data for demo purposes
  List<Movie> _getMockMovies() {
    return [
      Movie(
        id: 1,
        title: 'The Shawshank Redemption',
        overview:
            'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
        posterPath: '/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg',
        backdropPath: '/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg',
        voteAverage: 8.7,
        voteCount: 24500,
        releaseDate: '1994-09-23',
        genreIds: [18, 80],
        popularity: 150.5,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 2,
        title: 'The Godfather',
        overview:
            'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
        posterPath: '/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
        backdropPath: '/tmU7GeKVybMWFButWEGl2M4GeiP.jpg',
        voteAverage: 8.7,
        voteCount: 18400,
        releaseDate: '1972-03-14',
        genreIds: [18, 80],
        popularity: 145.3,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 3,
        title: 'The Dark Knight',
        overview:
            'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests.',
        posterPath: '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        backdropPath: '/hkBaDkMWbLaf8B1lsWsKX7Ew3Xq.jpg',
        voteAverage: 8.5,
        voteCount: 31200,
        releaseDate: '2008-07-16',
        genreIds: [18, 28, 80, 53],
        popularity: 180.7,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 4,
        title: 'Pulp Fiction',
        overview:
            'The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption.',
        posterPath: '/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
        backdropPath: '/suaEOtk1N1sgg2MTM7oZd2cfVp3.jpg',
        voteAverage: 8.5,
        voteCount: 26700,
        releaseDate: '1994-09-10',
        genreIds: [53, 80],
        popularity: 155.2,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 5,
        title: 'Inception',
        overview:
            'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea.',
        posterPath: '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        backdropPath: '/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
        voteAverage: 8.4,
        voteCount: 33400,
        releaseDate: '2010-07-15',
        genreIds: [28, 878, 12],
        popularity: 210.5,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 6,
        title: 'Forrest Gump',
        overview:
            'The presidencies of Kennedy and Johnson, the Vietnam War, and other historical events unfold from the perspective of an Alabama man.',
        posterPath: '/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg',
        backdropPath: '/7c9UVPPiTPltouxRVY6N9uCj9fT.jpg',
        voteAverage: 8.5,
        voteCount: 25800,
        releaseDate: '1994-06-23',
        genreIds: [35, 18, 10749],
        popularity: 167.8,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 7,
        title: 'The Matrix',
        overview:
            'A computer hacker learns from mysterious rebels about the true nature of his reality and his role in the war against its controllers.',
        posterPath: '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        backdropPath: '/icmmSD4vTTDKOq2vvdulafOGw93.jpg',
        voteAverage: 8.2,
        voteCount: 23600,
        releaseDate: '1999-03-30',
        genreIds: [28, 878],
        popularity: 195.4,
        originalLanguage: 'en',
        adult: false,
      ),
      Movie(
        id: 8,
        title: 'Interstellar',
        overview:
            'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
        posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        backdropPath: '/xu9zaAevzQ5nnrsXN6JcahLnG4i.jpg',
        voteAverage: 8.4,
        voteCount: 31800,
        releaseDate: '2014-11-05',
        genreIds: [12, 18, 878],
        popularity: 220.3,
        originalLanguage: 'en',
        adult: false,
      ),
    ];
  }
}
