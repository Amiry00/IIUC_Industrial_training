import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable error/empty/no-internet state widget.
class AppStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;

  const AppStateWidget({super.key, required this.icon, required this.title, required this.message, this.onRetry, this.retryText});

  factory AppStateWidget.noInternet({VoidCallback? onRetry}) => AppStateWidget(
    icon: Icons.wifi_off_rounded, title: 'No Internet Connection',
    message: 'Please check your connection and try again.', onRetry: onRetry,
  );

  factory AppStateWidget.error({String? message, VoidCallback? onRetry}) => AppStateWidget(
    icon: Icons.error_outline_rounded, title: 'Something Went Wrong',
    message: message ?? 'We couldn\'t load the data. Please try again.', onRetry: onRetry,
  );

  factory AppStateWidget.empty({String? title, String? message}) => AppStateWidget(
    icon: Icons.inbox_outlined, title: title ?? 'Nothing Here Yet',
    message: message ?? 'Start exploring air quality stations!',
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final textSecondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final accent = isDark ? AppColors.darkPrimaryAccent : AppColors.primaryAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: accent),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.sectionTitle(textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.body(textSecondary), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder.
class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  const ShimmerLoading({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? AppColors.darkCardColor : AppColors.secondaryBackground;
    final shimmerBg = isDark ? AppColors.darkSecondaryBackground : AppColors.cardColor;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: baseBg, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(height: 32, width: 100, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 8),
                Container(height: 24, width: 80, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(12))),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 18, width: double.infinity, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 10),
            Container(height: 14, width: 200, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(height: 28, width: 80, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 12),
                Container(height: 28, width: 60, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for Detail Screen.
class DetailShimmer extends StatelessWidget {
  const DetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPrimaryBackground : AppColors.primaryBackground;
    final shimmerBg = isDark ? AppColors.darkSecondaryBackground : AppColors.cardColor;

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 350, width: double.infinity, color: shimmerBg),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(height: 32, width: 80, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(16))),
                      const SizedBox(width: 8),
                      Container(height: 32, width: 80, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(16))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(height: 36, width: 250, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 24),
                  Container(height: 180, width: double.infinity, decoration: BoxDecoration(color: shimmerBg, borderRadius: BorderRadius.circular(24))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
