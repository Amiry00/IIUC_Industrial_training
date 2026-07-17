import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cinema/core/constants/api_constants.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/model/genre.dart';
import 'package:cinema/providers/watchlist_provider.dart';

class HeroBanner extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onWatchlistTap;

  const HeroBanner({
    super.key,
    required this.movie,
    this.onTap,
    this.onWatchlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWatchlisted = context.watch<WatchlistProvider>().watchlist.any((m) => m.id == movie.id);
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: size.height * AppDimensions.heroHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop image
            if (movie.backdropPath != null)
              CachedNetworkImage(
                imageUrl: ApiConstants.backdropUrl(movie.backdropPath),
                fit: BoxFit.cover,
                memCacheWidth: 800,
                placeholder: (_, _) => Container(color: Theme.of(context).colorScheme.surface),
                errorWidget: (_, _, _) => Container(color: Theme.of(context).colorScheme.surface),
              )
            else
              Container(color: Theme.of(context).colorScheme.surface),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(gradient: AppColors.heroGradient),
            ),

            // Top gradient (for status bar)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),

            // Content overlay
            Positioned(
              left: AppDimensions.paddingLarge,
              right: AppDimensions.paddingLarge,
              bottom: AppDimensions.paddingLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Genre chips
                  if (movie.genreIds.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: Genre.getGenreNames(movie.genreIds)
                          .take(3)
                          .map((name) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 4),

                  // Rating
                  if (movie.voteAverage > 0)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final rating = movie.voteAverage / 2;
                          return Icon(
                            index < rating.floor()
                                ? Icons.star_rounded
                                : (index < rating
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded),
                            color: Theme.of(context).colorScheme.secondary,
                            size: 18,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          movie.ratingText,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Buttons
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (onTap != null) onTap!();
                          },
                          icon: const Icon(Icons.info_outline_rounded, size: 20),
                          label: const Text('Details'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (isWatchlisted) {
                              context.read<WatchlistProvider>().removeFromWatchlist(movie.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Removed from Watchlist'),
                                  backgroundColor: Theme.of(context).cardColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            } else {
                              context.read<WatchlistProvider>().addToWatchlist(movie);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Added to Watchlist'),
                                  backgroundColor: Theme.of(context).cardColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          icon: Icon(isWatchlisted ? Icons.bookmark_rounded : Icons.bookmark_add_outlined, size: 20),
                          label: Text(isWatchlisted ? 'Added to Watchlist' : 'Add to Watchlist'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
