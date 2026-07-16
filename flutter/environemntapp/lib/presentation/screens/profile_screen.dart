import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final user = ref.watch(authProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final secondaryBg = isDark ? AppColors.darkSecondaryBackground : AppColors.secondaryBackground;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryAccent, AppColors.secondaryAccent.withOpacity(0.8)],
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, bg],
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: const Icon(Icons.eco_rounded, size: 50, color: AppColors.primaryAccent),
                          ),
                          const SizedBox(height: 16),
                          Text(user?.name ?? 'Air Quality Monitor Explorer', style: AppTypography.heroTitle(Colors.white).copyWith(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(user?.email ?? 'Monitoring air quality 🌍', style: AppTypography.caption(Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statCard('Favorites', '${ref.watch(favoritesProvider).length}', Icons.favorite_rounded, AppColors.error, cardBg, textPrimary, secondaryText),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),
                  _buildTile(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    mutedText: mutedText,
                    secondaryBg: secondaryBg,
                    onTap: () => context.push('/settings'),
                  ),
                  const SizedBox(height: 32),
                  _buildTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    isDestructive: true,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    mutedText: mutedText,
                    secondaryBg: secondaryBg,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(height: 40),
                  Center(child: Text(AppStrings.version, style: AppTypography.label(mutedText))),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap, bool isDestructive = false, required Color cardBg, required Color textPrimary, required Color mutedText, required Color secondaryBg}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive ? AppColors.error.withOpacity(0.1) : secondaryBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primaryAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body(isDestructive ? AppColors.error : textPrimary).copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.label(mutedText)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing else Icon(Icons.chevron_right_rounded, color: mutedText),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color cardBg, Color textPrimary, Color secondaryText) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.heroTitle(textPrimary).copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.label(secondaryText)),
          ],
        ),
      ),
    );
  }
}
