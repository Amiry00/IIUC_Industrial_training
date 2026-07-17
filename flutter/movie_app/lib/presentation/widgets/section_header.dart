import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/presentation/widgets/movie_card.dart';
import 'package:cinema/presentation/screens/detail/movie_detail_screen.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/data/repository/movie_repository.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLarge,
        vertical: AppDimensions.paddingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (onSeeAllTap != null)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final VoidCallback? onSeeAllTap;
  final double height;
  final double itemWidth;

  const MovieSection({
    super.key,
    required this.title,
    required this.movies,
    this.onSeeAllTap,
    this.height = 260,
    this.itemWidth = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onSeeAllTap: onSeeAllTap),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge),
              itemCount: movies.length > 10 ? 10 : movies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                movie: movie,
                width: itemWidth,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => DetailProvider(GetIt.I<MovieRepository>()),
                        child: MovieDetailScreen(movieId: movie.id, movie: movie),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ),
        ),
      ],
    );
  }
}
