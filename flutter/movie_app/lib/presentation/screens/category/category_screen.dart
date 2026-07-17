import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/genre.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/repository/movie_repository.dart';
import 'package:cinema/providers/movie_provider.dart';
import 'package:cinema/presentation/widgets/movie_card.dart';
import 'package:cinema/presentation/screens/detail/movie_detail_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:cinema/providers/detail_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int? _selectedGenreId = 28;
  List<Movie> _movies = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectGenre(28);
    });
  }

  @override
  Widget build(BuildContext context) {
    final genres = context.watch<MovieProvider>().genres;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text('Categories', style: Theme.of(context).textTheme.displayMedium),
          ),

          // Genre chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: genres.isEmpty ? Genre.defaultGenres.length : genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = genres.isEmpty ? Genre.defaultGenres[index] : genres[index];
                final isSelected = _selectedGenreId == genre.id;
                return ChoiceChip(
                  label: Text(genre.name),
                  selected: isSelected,
                  onSelected: (_) => _selectGenre(genre.id),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color!),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Grid
          Expanded(
            child: _selectedGenreId == null
                ? Center(child: Text('Select a genre to browse', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))))
                : _isLoading && _movies.isEmpty
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : _movies.isEmpty
                        ? Center(child: Text('No movies found', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scroll) {
                              if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200 && !_isLoading && _hasMore) {
                                _loadMore();
                              }
                              return false;
                            },
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, childAspectRatio: 0.55, crossAxisSpacing: 14, mainAxisSpacing: 14),
                              itemCount: _movies.length,
                              itemBuilder: (context, index) {
                                final movie = _movies[index];
                                return MovieCard(
                                  movie: movie,
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                      create: (_) => DetailProvider(GetIt.I<MovieRepository>()),
                                      child: MovieDetailScreen(movieId: movie.id, movie: movie),
                                    ),
                                  )),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectGenre(int genreId) async {
    setState(() { _selectedGenreId = genreId; _movies = []; _page = 1; _hasMore = true; _isLoading = true; });
    try {
      final movies = await GetIt.I<MovieRepository>().discoverByGenre(genreId: genreId, page: 1);
      setState(() { _movies = movies; _isLoading = false; if (movies.length < 20) _hasMore = false; });
    } catch (_) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_selectedGenreId == null || _isLoading) return;
    setState(() { _isLoading = true; });
    try {
      _page++;
      final movies = await GetIt.I<MovieRepository>().discoverByGenre(genreId: _selectedGenreId!, page: _page);
      setState(() { _movies.addAll(movies); _isLoading = false; if (movies.length < 20) _hasMore = false; });
    } catch (_) {
      setState(() { _isLoading = false; });
    }
  }
}
