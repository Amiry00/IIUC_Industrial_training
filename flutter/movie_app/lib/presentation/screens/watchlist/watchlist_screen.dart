import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/data/repository/movie_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinema/core/constants/api_constants.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/model/genre.dart' as genre_model;
import 'package:cinema/providers/watchlist_provider.dart';
import 'package:cinema/presentation/screens/detail/movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistProvider>().loadWatchlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.watchlist, style: Theme.of(context).textTheme.displayMedium),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: ['All', 'Favorites'].map((label) {
                final isActive = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isActive,
                    onSelected: (_) => setState(() => _filter = label),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).cardColor,
                    labelStyle: TextStyle(color: isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color!),
                  ),
                );
              }).toList(),
            ),
          ),

          // Sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Consumer<WatchlistProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    Text('Sort by: ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                    DropdownButton<WatchlistSort>(
                      value: provider.sortBy,
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: WatchlistSort.dateAdded, child: Text('Date Added')),
                        DropdownMenuItem(value: WatchlistSort.rating, child: Text('Rating')),
                        DropdownMenuItem(value: WatchlistSort.title, child: Text('Title')),
                      ],
                      onChanged: (v) { if (v != null) provider.setSortBy(v); },
                    ),
                  ],
                );
              },
            ),
          ),

          // Watchlist items
          Expanded(
            child: Consumer<WatchlistProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }

                final items = _filter == 'Favorites' ? provider.favorites : provider.watchlist;
                if (items.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bookmark_outline_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 64),
                    const SizedBox(height: 16),
                    Text(_filter == 'Favorites' ? 'No favorites yet' : 'Your watchlist is empty',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Add movies from the home screen', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                  ]));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movie = items[index];
                    return _buildWatchlistItem(context, movie, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(BuildContext context, Movie movie, WatchlistProvider provider) {
    return Dismissible(
      key: Key('watchlist_${movie.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppDimensions.cardRadius)),
        child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Remove from Watchlist', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text('Remove "${movie.title}"?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ],
        ));
      },
      onDismissed: (_) => provider.removeFromWatchlist(movie.id),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => DetailProvider(GetIt.I<MovieRepository>()),
            child: MovieDetailScreen(movieId: movie.id, movie: movie),
          ),
        )),
        onLongPress: () => _showEditDialog(context, movie, provider),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppDimensions.cardRadius)),
          child: Row(children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70, height: 100,
                child: movie.posterPath != null
                    ? CachedNetworkImage(imageUrl: ApiConstants.posterUrl(movie.posterPath), fit: BoxFit.cover)
                    : Container(color: Theme.of(context).colorScheme.surface, child: Center(child: Icon(Icons.movie_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (movie.year.isNotEmpty) Text(movie.year, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
              const SizedBox(height: 6),
              if (movie.genreIds.isNotEmpty)
                Wrap(spacing: 4, children: genre_model.Genre.getGenreNames(movie.genreIds).take(2).map((n) =>
                  Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)),
                    child: Text(n, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!, fontSize: 11)))).toList()),
              const SizedBox(height: 6),
              if (movie.voteAverage > 0) Row(children: [
                Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.secondary, size: 16),
                const SizedBox(width: 4),
                Text(movie.ratingText, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ])),
            // Favorite button
            IconButton(
              icon: Icon(movie.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: movie.isFavorite ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              onPressed: () => provider.toggleFavorite(movie.id),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Movie movie, WatchlistProvider provider) {
    final titleCtrl = TextEditingController(text: movie.title);
    final notesCtrl = TextEditingController(text: movie.userNotes ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text('Edit Movie', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), decoration: InputDecoration(hintText: 'Title', fillColor: Theme.of(context).colorScheme.surface)),
        const SizedBox(height: 12),
        TextField(controller: notesCtrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), maxLines: 3, decoration: InputDecoration(hintText: 'Your Notes', fillColor: Theme.of(context).colorScheme.surface)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          provider.updateWatchlistItem(movie.id, title: titleCtrl.text.trim(), userNotes: notesCtrl.text.trim());
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }
}
