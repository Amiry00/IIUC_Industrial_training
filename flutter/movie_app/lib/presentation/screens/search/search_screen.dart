import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/data/repository/movie_repository.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/providers/search_provider.dart';
import 'package:cinema/presentation/widgets/movie_card.dart';
import 'package:cinema/presentation/widgets/shimmer_loading.dart';
import 'package:cinema/presentation/screens/detail/movie_detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                return TextField(
                  onChanged: (q) => provider.search(q),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    suffixIcon: provider.query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            onPressed: () {
                              provider.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          // Results
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (provider.query.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'Search for your favorite movies',
                    icon: Icons.search_rounded,
                  );
                }

                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }

                if (provider.errorMessage.isNotEmpty) {
                  return ErrorStateWidget(message: provider.errorMessage);
                }

                if (provider.results.isEmpty) {
                  return const EmptyStateWidget(message: 'No movies found');
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
                      provider.loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: provider.results.length + (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.results.length) {
                        return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2));
                      }
                      final movie = provider.results[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
