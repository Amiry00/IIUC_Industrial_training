import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cinema/presentation/screens/player/video_player_screen.dart';
import 'package:cinema/core/constants/api_constants.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/model/cast.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/providers/watchlist_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:cinema/data/repository/movie_repository.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final Movie? movie;
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DetailProvider>().fetchMovieDetail(widget.movieId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<DetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (provider.errorMessage.isNotEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(provider.errorMessage, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => provider.fetchMovieDetail(widget.movieId), child: const Text('Retry')),
            ]));
          }
          final detail = provider.movieDetail;
          if (detail == null) return const SizedBox.shrink();
          return CustomScrollView(physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), slivers: [
                SliverToBoxAdapter(child: _buildBackdrop(context, detail)),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(detail.title, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (detail.year.isNotEmpty) Text(detail.year, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                      if (detail.runtimeFormatted.isNotEmpty) ...[
                        Text(' • ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        Text(detail.runtimeFormatted, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                      ],
                    ]),
                    const SizedBox(height: 12),
                    if (detail.genres.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: detail.genres.map((g) => Chip(label: Text(g.name))).toList()),
                    const SizedBox(height: 12),
                    _buildRating(detail),
                    const SizedBox(height: 20),
                    _buildButtons(provider, detail),
                    const SizedBox(height: 24),
                    Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Text(detail.overview, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    const SizedBox(height: 24),
                    if (detail.cast.isNotEmpty) _buildCastSection(detail),
                    if (detail.similar.isNotEmpty) _buildSimilarSection(detail),
                  ]),
                )),
              ]);
        },
      ),
    );
  }

  Widget _buildBackdrop(BuildContext context, MovieDetail detail) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: Stack(fit: StackFit.expand, children: [
        if (detail.backdropPath != null)
          CachedNetworkImage(imageUrl: ApiConstants.backdropUrl(detail.backdropPath), fit: BoxFit.cover)
        else Container(color: Theme.of(context).colorScheme.surface),
        Container(decoration: BoxDecoration(gradient: AppColors.heroGradient)),
        Positioned(top: MediaQuery.paddingOf(context).top + 8, left: 16,
          child: CircleAvatar(backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
            child: IconButton(icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.of(context).pop()))),
        Positioned(top: MediaQuery.paddingOf(context).top + 8, right: 16,
          child: CircleAvatar(backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
            child: IconButton(
              icon: Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.onSurface, size: 20),
              tooltip: 'Share',
              onPressed: () {
                final trailerUrl = detail.trailerId != null
                    ? 'https://www.youtube.com/watch?v=${detail.trailerId}'
                    : '';
                SharePlus.instance.share(
                  ShareParams(
                    text: '🎬 ${detail.title} (${detail.year})\n'
                        '⭐ ${detail.voteAverage.toStringAsFixed(1)}/10\n'
                        '${detail.genreText}\n\n'
                        '${detail.overview}\n\n'
                        '${trailerUrl.isNotEmpty ? 'Watch Trailer: $trailerUrl\n\n' : ''}'
                        'Shared via Cinema 🍿',
                  ),
                );
              },
            ))),
      ]),
    );
  }

  Widget _buildRating(MovieDetail detail) {
    if (detail.voteAverage == 0.0) {
      return Text('Not Rated', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16, fontStyle: FontStyle.italic));
    }
    return Row(children: [
      Text(
        detail.voteAverage.toStringAsFixed(1),
        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      Text('/10', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14)),
      const SizedBox(width: 6),
      const Text('⭐', style: TextStyle(fontSize: 16)),
    ]);
  }

  Widget _buildButtons(DetailProvider provider, MovieDetail detail) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
        if (detail.trailerId != null && detail.trailerId!.isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                  videoUrl: '',
                  detail: detail,
                  isTrailer: true,
                ),
              ));
            }, 
            icon: const Icon(Icons.play_circle_fill_rounded), 
            label: const Text('Trailer')
          ),
          const SizedBox(width: 12),
        ],
        OutlinedButton.icon(
          onPressed: () {
            final movie = widget.movie ?? Movie(id: detail.id, title: detail.title, overview: detail.overview, posterPath: detail.posterPath, backdropPath: detail.backdropPath, voteAverage: detail.voteAverage, releaseDate: detail.releaseDate, genreIds: detail.genres.map((g) => g.id).toList());
            provider.toggleWatchlist(movie);
            context.read<WatchlistProvider>().loadWatchlist();
          }, 
          icon: Icon(provider.isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_add_outlined), 
          label: Text(provider.isInWatchlist ? 'Added to Watchlist' : 'Add to Watchlist'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ]),
    );
  }

  Widget _buildCastSection(MovieDetail detail) {
    final displayCast = detail.cast.take(10).toList();
    final hasMore = detail.cast.length > 10;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Cast', style: Theme.of(context).textTheme.titleLarge),
          if (hasMore)
            TextButton(
              onPressed: () {
                // Show all cast in a bottom sheet
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _buildAllCastSheet(detail),
                );
              },
              child: Text('View All', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 100, 
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal, 
            itemCount: displayCast.length, 
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = displayCast[i];
              return SizedBox(width: 60, child: Column(children: [
                c.profilePath != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: ApiConstants.profileUrl(c.profilePath),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          memCacheWidth: 150,
                          placeholder: (_, _) => Container(color: Theme.of(context).cardColor),
                          errorWidget: (_, _, _) => Container(
                            color: Theme.of(context).cardColor,
                            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).cardColor,
                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                const SizedBox(height: 6),
                Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 10)),
              ]));
            }
          )
        )
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildAllCastSheet(MovieDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Full Cast', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 80,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.6,
              ),
              itemCount: detail.cast.length,
              itemBuilder: (_, i) {
                final c = detail.cast[i];
                return Column(children: [
                  c.profilePath != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: ApiConstants.profileUrl(c.profilePath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            memCacheWidth: 150,
                            placeholder: (_, _) => Container(color: Theme.of(context).cardColor),
                            errorWidget: (_, _, _) => Container(
                              color: Theme.of(context).cardColor,
                              child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).cardColor,
                          child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        ),
                  const SizedBox(height: 6),
                  Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 10)),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection(MovieDetail detail) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('More Like This', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      SizedBox(
        height: 220,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal, 
            itemCount: detail.similar.length, 
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final s = detail.similar[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => DetailProvider(GetIt.I<MovieRepository>()),
                  child: MovieDetailScreen(movieId: s.id),
                ),
              )),
                child: SizedBox(width: 130, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                    child: s.posterPath != null ? CachedNetworkImage(imageUrl: ApiConstants.posterUrl(s.posterPath), fit: BoxFit.cover, width: double.infinity)
                      : Container(color: Theme.of(context).cardColor, child: Center(child: Icon(Icons.movie_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))))),
                  const SizedBox(height: 8),
                  Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500)),
                ])),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }
}
