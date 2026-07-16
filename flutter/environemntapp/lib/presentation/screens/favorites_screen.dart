import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/providers.dart';
import '../widgets/station_card.dart';
import '../widgets/common_widgets.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum SortOption { name, aqi, date }

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  SortOption _sortOption = SortOption.date;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected() {
    for (final id in _selectedIds) {
      final station = ref.read(favoritesProvider).firstWhere((s) => s.id == id);
      ref.read(favoritesProvider.notifier).toggle(station);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPrimaryBackground : AppColors.primaryBackground;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    var favorites = List.of(ref.watch(favoritesProvider));

    // Sort
    favorites.sort((a, b) {
      if (_sortOption == SortOption.name) return a.name.compareTo(b.name);
      if (_sortOption == SortOption.aqi) return b.aqiFromPm25.compareTo(a.aqiFromPm25); // Highest AQI first
      return (b.lastUpdated ?? DateTime.now()).compareTo(a.lastUpdated ?? DateTime.now());
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : 'Favorites', style: AppTypography.sectionTitle(textPrimary)),
        backgroundColor: bg,
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: textPrimary),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                }),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
                onPressed: () => context.pop(),
              ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _deleteSelected,
            )
          else ...[
            PopupMenuButton<SortOption>(
              icon: Icon(Icons.sort_rounded, color: textPrimary),
              color: Theme.of(context).cardColor,
              onSelected: (option) => setState(() => _sortOption = option),
              itemBuilder: (context) => [
                PopupMenuItem(value: SortOption.date, child: Text('Sort by Latest', style: AppTypography.body(textPrimary))),
                PopupMenuItem(value: SortOption.aqi, child: Text('Sort by Highest AQI', style: AppTypography.body(textPrimary))),
                PopupMenuItem(value: SortOption.name, child: Text('Sort by Name', style: AppTypography.body(textPrimary))),
              ],
            ),
          ],
        ],
      ),
      body: favorites.isEmpty
          ? AppStateWidget.empty(title: 'No Favorites Yet', message: 'Tap the heart icon to save your favorite stations.')
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              itemBuilder: (_, i) {
                final station = favorites[i];
                final isSelected = _selectedIds.contains(station.id);

                return Stack(
                  children: [
                    StationCard(
                      station: station,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(station.id);
                        } else {
                          context.push('/detail/${station.id}');
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(station.id);
                          });
                        }
                      },
                      onFavorite: _isSelectionMode ? null : () => ref.read(favoritesProvider.notifier).toggle(station),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        right: 16,
                        top: 16,
                        child: GestureDetector(
                          onTap: () => _toggleSelection(station.id),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                              border: Border.all(color: isSelected ? AppColors.primaryAccent : mutedText, width: 2),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
