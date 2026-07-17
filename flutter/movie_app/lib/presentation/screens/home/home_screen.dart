import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/providers/movie_provider.dart';
import 'package:cinema/providers/watchlist_provider.dart';
import 'package:cinema/presentation/widgets/hero_banner.dart';
import 'package:cinema/presentation/widgets/movie_card.dart';
import 'package:cinema/presentation/widgets/section_header.dart';
import 'package:cinema/presentation/widgets/shimmer_loading.dart';
import 'package:cinema/presentation/screens/detail/movie_detail_screen.dart';
import 'package:cinema/presentation/screens/search/search_screen.dart';
import 'package:cinema/presentation/screens/watchlist/watchlist_screen.dart';
import 'package:cinema/presentation/screens/profile/profile_screen.dart';
import 'package:cinema/presentation/screens/category/category_screen.dart';
import 'package:cinema/presentation/widgets/keep_alive_wrapper.dart';
import 'package:get_it/get_it.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/data/repository/movie_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().initialize();
    });
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          RepaintBoundary(child: KeepAliveWrapper(child: _HomeContent())),
          RepaintBoundary(child: KeepAliveWrapper(child: SearchScreen())),
          RepaintBoundary(child: KeepAliveWrapper(child: CategoryScreen())),
          RepaintBoundary(child: KeepAliveWrapper(child: WatchlistScreen())),
          RepaintBoundary(child: KeepAliveWrapper(child: ProfileScreen())),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.jumpToPage(index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  void _navigateToDetail(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChangeNotifierProvider(
              create: (_) => DetailProvider(GetIt.I<MovieRepository>()),
              child: MovieDetailScreen(movieId: movie.id, movie: movie),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MovieProvider, LoadingState>(
      selector: (_, provider) => provider.state,
      builder: (context, state, _) {
        final isTrendingEmpty = context.select<MovieProvider, bool>((p) => p.trending.isEmpty);
        final errorMessage = context.select<MovieProvider, String>((p) => p.errorMessage);

        if (state == LoadingState.loading && isTrendingEmpty) {
          return const ShimmerLoading();
        }

        if (state == LoadingState.error && isTrendingEmpty) {
          return ErrorStateWidget(
            message: errorMessage,
            onRetry: () => context.read<MovieProvider>().initialize(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<MovieProvider>().refresh(),
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            slivers: [
              // Hero Banner
              Selector<MovieProvider, Movie?>(
                selector: (_, p) => p.featuredMovie,
                builder: (context, featuredMovie, _) {
                  if (featuredMovie == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: HeroBanner(
                      movie: featuredMovie,
                      onTap: () =>
                          _navigateToDetail(context, featuredMovie),
                      onWatchlistTap: () {
                        context
                            .read<WatchlistProvider>()
                            .addToWatchlist(featuredMovie);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to Watchlist'),
                            backgroundColor: Theme.of(context).cardColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Trending Now
              Selector<MovieProvider, List<Movie>>(
                selector: (_, p) => p.trending,
                builder: (context, trending, _) {
                  if (trending.length <= 1) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: _buildMovieSection(
                      context,
                      AppStrings.trending,
                      trending.skip(1).toList(),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Popular
              Selector<MovieProvider, List<Movie>>(
                selector: (_, p) => p.popular,
                builder: (context, popular, _) {
                  if (popular.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: _buildMovieSection(
                      context,
                      AppStrings.popular,
                      popular,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Top Rated
              Selector<MovieProvider, List<Movie>>(
                selector: (_, p) => p.topRated,
                builder: (context, topRated, _) {
                  if (topRated.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: _buildMovieSection(
                      context,
                      AppStrings.topRated,
                      topRated,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Now Playing
              Selector<MovieProvider, List<Movie>>(
                selector: (_, p) => p.nowPlaying,
                builder: (context, nowPlaying, _) {
                  if (nowPlaying.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: _buildMovieSection(
                      context,
                      AppStrings.nowPlaying,
                      nowPlaying,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Upcoming
              Selector<MovieProvider, List<Movie>>(
                selector: (_, p) => p.upcoming,
                builder: (context, upcoming, _) {
                  if (upcoming.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: _buildMovieSection(
                      context,
                      AppStrings.upcoming,
                      upcoming,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMovieSection(
      BuildContext context, String title, List<Movie> movies) {
    return MovieSection(
      title: title,
      movies: movies,
    );
  }
}
