import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/model/air_parameter.dart';
import '../providers/providers.dart';
import '../widgets/station_card.dart';
import '../widgets/common_widgets.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPrimaryBackground : AppColors.primaryBackground;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final selected = ref.watch(selectedParameterProvider);
    final parameters = AirParameter.values;
    final stationsAsync = ref.watch(parameterStationsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: Text('Explore', style: AppTypography.sectionTitle(textPrimary)), backgroundColor: bg),
      body: Column(
        children: [
          // Parameter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: parameters.length,
              itemBuilder: (_, i) {
                final param = parameters[i];
                final isSelected = (param == AirParameter.all && selected == null) ||
                    selected == param;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: isSelected ? null : Icon(param.icon, size: 18, color: param.color),
                    label: Text(
                      param.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: param == AirParameter.all
                        ? (isDark ? AppColors.darkPrimaryAccent : AppColors.primaryAccent)
                        : param.color,
                    onSelected: (_) {
                      if (param == AirParameter.all) {
                        ref.read(selectedParameterProvider.notifier).state = null;
                      } else {
                        ref.read(selectedParameterProvider.notifier).state =
                            isSelected ? null : param;
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Stations
          Expanded(
            child: stationsAsync.when(
              data: (stations) {
                if (stations.isEmpty) {
                  return AppStateWidget.empty(
                    title: 'No Stations',
                    message: 'No stations found for this parameter yet.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: stations.length,
                  itemBuilder: (_, i) => StationCard(
                    station: stations[i],
                    onTap: () => context.push('/detail/${stations[i].id}'),
                    onFavorite: () {
                      ref.read(favoritesProvider.notifier).toggle(stations[i]);
                      ref.invalidate(parameterStationsProvider);
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: ShimmerLoading(),
              ),
              error: (e, _) => AppStateWidget.error(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
