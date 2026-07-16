import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/debouncer.dart';
import '../../data/model/station.dart';
import '../../data/model/air_parameter.dart';
import '../providers/providers.dart';
import '../widgets/station_card.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPrimaryBackground : AppColors.primaryBackground;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final textSecondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final secondaryBg = isDark ? AppColors.darkSecondaryBackground : AppColors.secondaryBackground;
    final cardBg = isDark ? AppColors.darkCardColor : AppColors.cardColor;

    final state = ref.watch(stationsProvider);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: () => ref.read(stationsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: bg,
              elevation: 0,
              toolbarHeight: 80,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Air Quality', style: AppTypography.caption(mutedText)),
                  Text('Monitor 🌿', style: AppTypography.sectionTitle(textPrimary)),
                ],
              ),

            ),
            SliverToBoxAdapter(
              child: _buildSearchBar(textPrimary, mutedText),
            ),
            if (_searchController.text.isNotEmpty)
              _buildSearchResults()
            else if (_searchFocusNode.hasFocus && ref.watch(searchHistoryProvider).isNotEmpty)
              _buildSearchHistory(textPrimary, mutedText)
            else ...[
              if (state.isLoading && state.stations.isEmpty)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: ShimmerLoading()))
              else ...[
                Consumer(
                  builder: (context, ref, child) {
                    final currentLocationState = ref.watch(currentLocationAqProvider);
                    return currentLocationState.when(
                      data: (station) {
                        if (station != null) {
                          return SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: AppColors.primaryAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Current Location', style: AppTypography.label(mutedText)),
                                    ],
                                  ),
                                ),
                                _buildHeroBanner(station, bg, mutedText, textPrimary, textSecondary),
                              ],
                            ),
                          );
                        } else if (state.stations.isNotEmpty) {
                          return SliverToBoxAdapter(child: _buildHeroBanner(state.stations.first, bg, mutedText, textPrimary, textSecondary));
                        }
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      },
                      loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))),
                      error: (_, __) => state.stations.isNotEmpty 
                        ? SliverToBoxAdapter(child: _buildHeroBanner(state.stations.first, bg, mutedText, textPrimary, textSecondary))
                        : const SliverToBoxAdapter(child: SizedBox.shrink()),
                    );
                  },
                ),
                
                // Highest and Lowest AQI
                if (state.stations.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final sorted = List.of(state.stations)
                        ..sort((a, b) => (b.aqiFromPm25).compareTo(a.aqiFromPm25));
                      return SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (sorted.isNotEmpty)
                              _buildHorizontalSection('Highest AQI', [sorted.first], textPrimary),
                            if (sorted.length > 1)
                              _buildHorizontalSection('Lowest AQI', [sorted.last], textPrimary),
                          ],
                        ),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final recentlyViewed = ref.watch(recentlyViewedProvider);
                      if (recentlyViewed.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                      return SliverToBoxAdapter(
                        child: _buildHorizontalSection('Recently Viewed', recentlyViewed, textPrimary),
                      );
                    },
                  ),
                  SliverToBoxAdapter(child: _buildParameterCarousel(textPrimary, cardBg)),
                  SliverToBoxAdapter(child: _buildHorizontalSection('Global Stations', state.stations.skip(1).take(5).toList(), textPrimary)),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ]
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(AqStation station) {
    ref.read(recentlyViewedProvider.notifier).add(station.id);
    context.push('/detail/${station.id}');
  }

  Widget _buildSearchBar(Color textPrimary, Color mutedText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: AppTypography.body(textPrimary),
        decoration: InputDecoration(
          hintText: 'Search stations, countries...',
          prefixIcon: Icon(Icons.search_rounded, color: mutedText),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: mutedText),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primaryAccent, size: 20),
                ),
        ),
        onChanged: (v) {
          setState(() {});
          _debouncer.run(() => ref.read(searchQueryProvider.notifier).state = v);
        },
      ),
    );
  }

  Widget _buildHeroBanner(AqStation station, Color bg, Color mutedText, Color textPrimary, Color textSecondary) {
    final aqi = station.aqiFromPm25;
    final aqiColor = AppColors.getAqiColor(aqi);
    final aqiLabel = AppColors.getAqiLabel(aqi);
    final pm25 = station.pm25Reading;

    return GestureDetector(
      onTap: () => _navigateToDetail(station),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [aqiColor.withOpacity(0.2), aqiColor.withOpacity(0.05), bg],
          ),
          border: Border.all(color: aqiColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: aqiColor.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: aqiColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(aqiLabel, style: AppTypography.label(Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: aqiColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.air_rounded, color: aqiColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Large AQI value
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pm25 != null ? pm25.value.toStringAsFixed(1) : '--',
                  style: AppTypography.heroTitle(textPrimary).copyWith(fontSize: 48),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('µg/m³ PM2.5', style: AppTypography.caption(mutedText)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              station.name,
              style: AppTypography.cardTitle(textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Text(station.country, style: AppTypography.caption(textSecondary)),
                const Spacer(),
                Text('View Details', style: AppTypography.button(AppColors.primaryAccent).copyWith(fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryAccent, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<AqStation> stations, Color textPrimary) {
    if (stations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.sectionTitle(textPrimary)),
              GestureDetector(
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                child: Row(
                  children: [
                    Text('See All', style: AppTypography.label(AppColors.primaryAccent)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primaryAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: stations.length,
            itemBuilder: (context, index) {
              return StationCardCompact(
                station: stations[index],
                onTap: () => _navigateToDetail(stations[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParameterCarousel(Color textPrimary, Color cardBg) {
    final parameters = AirParameter.values.where((p) => p != AirParameter.all).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Text('Air Parameters', style: AppTypography.sectionTitle(textPrimary)),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: parameters.length,
            itemBuilder: (context, index) {
              final param = parameters[index];
              return GestureDetector(
                onTap: () {
                  ref.read(selectedParameterProvider.notifier).state = param;
                  ref.read(bottomNavIndexProvider.notifier).state = 1;
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [param.color.withOpacity(0.2), cardBg],
                    ),
                    border: Border.all(color: param.color.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: param.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(param.icon, color: param.color, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        param.displayName,
                        style: AppTypography.label(textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final results = ref.watch(searchResultsProvider);
    return results.when(
      data: (stations) {
        if (stations.isEmpty) return SliverToBoxAdapter(child: AppStateWidget.empty(title: 'No Results', message: 'Try a different search term.'));
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (ctx, i) => StationCard(station: stations[i], onTap: () => _navigateToDetail(stations[i])),
            childCount: stations.length,
          )),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ShimmerLoading(itemCount: 2))),
      error: (e, _) => SliverToBoxAdapter(child: AppStateWidget.error(message: e.toString())),
    );
  }

  Widget _buildSearchHistory(Color textPrimary, Color mutedText) {
    final history = ref.watch(searchHistoryProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: AppTypography.sectionTitle(textPrimary).copyWith(fontSize: 16)),
                TextButton(
                  onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                  child: Text('Clear', style: AppTypography.label(AppColors.primaryAccent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history.map((query) => GestureDetector(
                onTap: () {
                  _searchController.text = query;
                  ref.read(searchQueryProvider.notifier).state = query;
                  _searchFocusNode.unfocus();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: mutedText.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: mutedText),
                      const SizedBox(width: 6),
                      Text(query, style: AppTypography.body(textPrimary)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
