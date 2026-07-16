import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/model/station.dart';

/// Full station card with press animation and sensor readings.
class StationCard extends StatefulWidget {
  final AqStation station;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavorite;

  const StationCard({super.key, required this.station, required this.onTap, this.onLongPress, this.onFavorite});

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() => _controller.reverse();

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleLongPress() {
    if (widget.onLongPress != null) {
      HapticFeedback.mediumImpact();
      widget.onLongPress!();
    }
  }

  void _handleFavorite() {
    HapticFeedback.selectionClick();
    widget.onFavorite?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final secondaryBg = isDark ? AppColors.darkSecondaryBackground : AppColors.secondaryBackground;
    final dividerColor = Theme.of(context).dividerColor;

    final aqi = widget.station.aqiFromPm25;
    final aqiColor = AppColors.getAqiColor(aqi);
    final aqiLabel = AppColors.getAqiLabel(aqi);
    final pm25 = widget.station.pm25Reading;
    final temp = widget.station.temperatureReading;
    final humid = widget.station.humidityReading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AQI color accent
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [aqiColor.withOpacity(0.15), cardBg],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // AQI Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: aqiColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.air_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                pm25 != null ? '${pm25.value.toStringAsFixed(1)}' : '--',
                                style: AppTypography.label(Colors.white).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(width: 3),
                              Text('µg/m³', style: AppTypography.overline(Colors.white70).copyWith(fontSize: 9)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: aqiColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: aqiColor.withOpacity(0.3)),
                            ),
                            child: Text(aqiLabel, style: AppTypography.label(aqiColor).copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Monitor/Mobile badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: secondaryBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.station.isMonitor ? Icons.monitor_heart_outlined : Icons.sensors_rounded,
                            size: 14,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Station name
                    Text(
                      widget.station.name,
                      style: AppTypography.cardTitle(textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Country & provider
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.station.country} (${widget.station.countryCode})',
                            style: AppTypography.caption(secondaryText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sensor readings strip
              if (temp != null || humid != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      if (temp != null) ...[
                        _miniReading(Icons.thermostat_outlined, '${temp.value.toStringAsFixed(1)}°C', AppColors.renewableEnergy, secondaryBg),
                        const SizedBox(width: 12),
                      ],
                      if (humid != null)
                        _miniReading(Icons.water_drop_outlined, '${humid.value.toStringAsFixed(0)}%', AppColors.climateChange, secondaryBg),
                      const Spacer(),
                      Text(
                        '${widget.station.latestReadings.length} sensors',
                        style: AppTypography.label(mutedText),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: dividerColor),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Icon(Icons.business_outlined, size: 14, color: mutedText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.station.provider,
                        style: AppTypography.label(mutedText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.station.lastUpdated != null) ...[
                      Icon(Icons.access_time_rounded, size: 14, color: mutedText),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.getRelativeTime(widget.station.lastUpdated!),
                        style: AppTypography.overline(mutedText),
                      ),
                    ],
                    if (widget.onFavorite != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _handleFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.station.isFavorite ? AppColors.error.withOpacity(0.1) : secondaryBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.station.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: widget.station.isFavorite ? AppColors.error : mutedText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniReading(IconData icon, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(value, style: AppTypography.label(color).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Compact horizontal station card for carousels.
class StationCardCompact extends StatefulWidget {
  final AqStation station;
  final VoidCallback onTap;

  const StationCardCompact({super.key, required this.station, required this.onTap});

  @override
  State<StationCardCompact> createState() => _StationCardCompactState();
}

class _StationCardCompactState extends State<StationCardCompact> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final aqi = widget.station.aqiFromPm25;
    final aqiColor = AppColors.getAqiColor(aqi);
    final aqiLabel = AppColors.getAqiLabel(aqi);
    final pm25 = widget.station.pm25Reading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          width: 220,
          margin: const EdgeInsets.only(right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AQI color bar
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [aqiColor.withOpacity(0.3), aqiColor.withOpacity(0.1)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pm25 != null ? pm25.value.toStringAsFixed(1) : '--',
                        style: AppTypography.heroTitle(aqiColor).copyWith(fontSize: 28),
                      ),
                      Text('PM2.5 µg/m³', style: AppTypography.overline(aqiColor)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: aqiColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(aqiLabel, style: AppTypography.overline(aqiColor)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.station.name,
                      style: AppTypography.cardTitle(textPrimary).copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: mutedText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.station.countryCode.isNotEmpty
                                ? widget.station.countryCode
                                : widget.station.country,
                            style: AppTypography.label(mutedText),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${widget.station.latestReadings.length}',
                          style: AppTypography.label(mutedText),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.sensors_rounded, size: 12, color: mutedText),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular AQI gauge widget for detail screen.
class AqiGauge extends StatelessWidget {
  final int aqi;
  final double size;

  const AqiGauge({super.key, required this.aqi, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryText;
    final aqiColor = AppColors.getAqiColor(aqi);
    final aqiLabel = AppColors.getAqiLabel(aqi);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: aqi.toDouble()),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final currentAqi = value.toInt();
          return CustomPaint(
            painter: _AqiGaugePainter(aqi: currentAqi, aqiColor: aqiColor),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$currentAqi',
                    style: AppTypography.heroTitle(aqiColor).copyWith(fontSize: size * 0.28),
                  ),
                  Text('AQI', style: AppTypography.overline(textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    aqiLabel,
                    style: AppTypography.label(aqiColor).copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AqiGaugePainter extends CustomPainter {
  final int aqi;
  final Color aqiColor;

  _AqiGaugePainter({required this.aqi, required this.aqiColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background arc
    final bgPaint = Paint()
      ..color = aqiColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4, // Start angle (bottom-left)
      4.9, // Sweep angle (almost full circle)
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..color = aqiColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final progress = (aqi / 500).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4,
      4.9 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AqiGaugePainter oldDelegate) =>
      oldDelegate.aqi != aqi || oldDelegate.aqiColor != aqiColor;
}

/// Sensor reading tile for detail screen grid.
class SensorReadingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const SensorReadingTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.label(mutedText), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(value, style: AppTypography.cardTitle(textPrimary).copyWith(fontSize: 20), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: AppTypography.overline(mutedText), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
