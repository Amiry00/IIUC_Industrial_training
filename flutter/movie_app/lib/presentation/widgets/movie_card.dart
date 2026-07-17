import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinema/core/constants/api_constants.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double width;
  final bool showTitle;
  final bool showRating;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width = 140,
    this.showTitle = true,
    this.showRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  color: Theme.of(context).cardColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      movie.posterPath != null && movie.posterPath!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ApiConstants.posterUrl(movie.posterPath),
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              placeholder: (_, _) => Container(
                                color: Theme.of(context).cardColor,
                                child: Center(
                                  child: Icon(Icons.movie_outlined,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 32),
                                ),
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: Theme.of(context).cardColor,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 32),
                                ),
                              ),
                            )
                          : Container(
                              color: Theme.of(context).cardColor,
                              child: Center(
                                child: Text(
                                  movie.title.isNotEmpty ? movie.title[0] : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),

                      // Rating badge
                      if (showRating && movie.voteAverage > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Theme.of(context).colorScheme.secondary, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  movie.ratingText,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Title
            if (showTitle) ...[
              const SizedBox(height: 8),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (movie.year.isNotEmpty)
                Text(
                  movie.year,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
