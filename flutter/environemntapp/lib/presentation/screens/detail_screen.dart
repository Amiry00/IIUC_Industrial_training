import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/model/station.dart';
import '../providers/providers.dart';
import '../widgets/station_card.dart';
import '../widgets/common_widgets.dart';

class DetailScreen extends ConsumerWidget {
  final String stationId;
  const DetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final secondaryBg = isDark ? AppColors.darkSecondaryBackground : AppColors.secondaryBackground;

    final id = int.tryParse(stationId) ?? 0;
    final stationAsync = ref.watch(stationDetailProvider(id));

    return stationAsync.when(
      data: (station) {
        if (station == null) {
          return Scaffold(
            backgroundColor: bg,
            body: AppStateWidget.error(
              message: 'Station not found',
              onRetry: () => context.pop(),
            ),
          );
        }

        final aqi = station.aqiFromPm25;
        final aqiColor = AppColors.getAqiColor(aqi);
        final aqiLabel = AppColors.getAqiLabel(aqi);

        return Scaffold(
          backgroundColor: bg,
          body: RefreshIndicator(
            color: AppColors.primaryAccent,
            onRefresh: () async {
              ref.invalidate(stationDetailProvider(id));
              await ref.read(stationDetailProvider(id).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // App Bar with gradient
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: bg,
                leading: _buildGlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                  margin: const EdgeInsets.all(8),
                ),
                actions: [
                  _buildGlassButton(
                    icon: ref.watch(favoritesProvider).any((s) => s.id == station.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: ref.watch(favoritesProvider).any((s) => s.id == station.id)
                        ? AppColors.error
                        : Colors.white,
                    onTap: () => ref.read(favoritesProvider.notifier).toggle(station),
                    margin: const EdgeInsets.all(8),
                  ),
                  _buildGlassButton(
                    icon: Icons.ios_share_rounded,
                    onTap: () => Share.share(
                        '${station.name} - Air Quality\n'
                        'AQI: $aqi ($aqiLabel)\n'
                        'PM2.5: ${station.pm25Reading?.value.toStringAsFixed(1) ?? "N/A"} µg/m³\n'
                        'Location: ${station.country}'),
                    margin: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          aqiColor.withOpacity(0.3),
                          aqiColor.withOpacity(0.1),
                          bg,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: AqiGauge(aqi: aqi, size: 160),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AQI label badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: aqiColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: aqiColor.withOpacity(0.3)),
                            ),
                            child: Text(aqiLabel, style: AppTypography.label(aqiColor)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: secondaryBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  station.isMonitor ? Icons.monitor_heart_outlined : Icons.sensors_rounded,
                                  size: 14,
                                  color: mutedText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  station.isMonitor ? 'Monitor' : 'Sensor',
                                  style: AppTypography.label(mutedText),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text('${station.latestReadings.length} sensors', style: AppTypography.label(mutedText)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Station name
                      Text(station.name, style: AppTypography.heroTitle(textPrimary).copyWith(fontSize: 28)),
                      const SizedBox(height: 12),
                      // Station info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _infoRow(Icons.location_on_outlined, 'Country', '${station.country} (${station.countryCode})', textPrimary, mutedText),
                            _infoRow(Icons.business_outlined, 'Provider', station.provider, textPrimary, mutedText),
                            _infoRow(Icons.schedule_outlined, 'Timezone', station.timezone, textPrimary, mutedText),
                            _infoRow(Icons.gps_fixed_outlined, 'Coordinates',
                                '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}',
                                textPrimary, mutedText),
                            if (station.lastUpdated != null)
                              _infoRow(Icons.update_outlined, 'Last Updated',
                                  DateFormatter.formatDateWithTime(station.lastUpdated!),
                                  textPrimary, mutedText),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Sensor Readings header
                      Text('Sensor Readings', style: AppTypography.sectionTitle(textPrimary)),
                      const SizedBox(height: 16),
                      // Readings grid
                      if (station.latestReadings.isNotEmpty)
                        _buildReadingsGrid(station, textPrimary, mutedText)
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.sensors_off_rounded, size: 48, color: mutedText),
                                const SizedBox(height: 12),
                                Text('No recent readings available', style: AppTypography.body(mutedText)),
                              ],
                            ),
                          ),
                        ),
                      
                      // Chart
                      if (station.latestReadings.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text('Readings Overview', style: AppTypography.sectionTitle(textPrimary)),
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 24),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: _buildChart(station, textPrimary, mutedText),
                        ),
                      ],

                      // User notes
                      if (station.userNotes.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.note_outlined, color: AppColors.primaryAccent, size: 24),
                                  const SizedBox(width: 12),
                                  Text('My Notes', style: AppTypography.sectionTitle(AppColors.primaryAccent)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(station.userNotes, style: AppTypography.body(textPrimary)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
      loading: () => const DetailShimmer(),
      error: (e, _) => Scaffold(
        backgroundColor: bg,
        body: AppStateWidget.error(message: e.toString(), onRetry: () => ref.invalidate(stationDetailProvider(id))),
      ),
    );
  }

  Widget _buildReadingsGrid(AqStation station, Color textPrimary, Color mutedText) {
    final readings = station.latestReadings.where((r) => r.value > 0).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: readings.length,
      itemBuilder: (_, i) {
        final reading = readings[i];
        final color = _getParameterColor(reading.parameterName);
        final icon = _getParameterIcon(reading.parameterName);

        return SensorReadingTile(
          icon: icon,
          label: reading.displayName.isNotEmpty ? reading.displayName : reading.parameterName,
          value: reading.value.toStringAsFixed(1),
          unit: reading.units,
          color: color,
        );
      },
    );
  }

  Color _getParameterColor(String paramName) {
    switch (paramName) {
      case 'pm25':
        return AppColors.aqiUnhealthy;
      case 'pm10':
        return AppColors.aqiUnhealthySensitive;
      case 'pm1':
        return AppColors.aqiModerate;
      case 'o3':
        return AppColors.climateChange;
      case 'no2':
        return AppColors.pollution;
      case 'so2':
        return AppColors.aqiVeryUnhealthy;
      case 'co':
        return AppColors.aqiHazardous;
      case 'temperature':
        return AppColors.renewableEnergy;
      case 'relativehumidity':
        return AppColors.wildlife;
      default:
        return AppColors.primaryAccent;
    }
  }

  IconData _getParameterIcon(String paramName) {
    switch (paramName) {
      case 'pm25':
        return Icons.grain_rounded;
      case 'pm10':
        return Icons.blur_on_rounded;
      case 'pm1':
        return Icons.blur_circular_rounded;
      case 'o3':
        return Icons.cloud_outlined;
      case 'no2':
        return Icons.factory_outlined;
      case 'so2':
        return Icons.science_outlined;
      case 'co':
        return Icons.local_fire_department_outlined;
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'relativehumidity':
        return Icons.water_drop_outlined;
      default:
        return Icons.sensors_rounded;
    }
  }

  Widget _buildChart(AqStation station, Color textPrimary, Color mutedText) {
    final readings = station.latestReadings.where((r) => r.value > 0).take(6).toList();
    if (readings.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: readings.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= readings.length) return const SizedBox.shrink();
                final reading = readings[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0, right: 8.0),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      reading.displayName.isNotEmpty ? reading.displayName : reading.parameterName,
                      style: AppTypography.overline(textPrimary).copyWith(fontSize: 10),
                      softWrap: false,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: AppTypography.overline(mutedText),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: mutedText.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: readings.asMap().entries.map((entry) {
          final color = _getParameterColor(entry.value.parameterName);
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: color,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color textPrimary, Color mutedText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: mutedText),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: AppTypography.label(mutedText)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.caption(textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, EdgeInsets? margin, Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
