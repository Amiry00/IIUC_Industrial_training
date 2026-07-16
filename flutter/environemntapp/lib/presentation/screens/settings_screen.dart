import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final secondaryBg = isDark ? AppColors.darkSecondaryBackground : AppColors.secondaryBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: AppTypography.sectionTitle(textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Preferences', style: AppTypography.sectionTitle(textPrimary)),
          const SizedBox(height: 16),
          _buildTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            cardBg: cardBg,
            textPrimary: textPrimary,
            mutedText: mutedText,
            secondaryBg: secondaryBg,
            trailing: Switch.adaptive(
              value: themeState == ThemeMode.dark,
              activeTrackColor: AppColors.primaryAccent,
              activeColor: Colors.white,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),

          const SizedBox(height: 32),
          Text('Data & Storage', style: AppTypography.sectionTitle(textPrimary)),
          const SizedBox(height: 16),
          _buildTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear Cache',
            isDestructive: true,
            cardBg: cardBg,
            textPrimary: textPrimary,
            mutedText: mutedText,
            secondaryBg: secondaryBg,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text('Clear Cache', style: AppTypography.cardTitle(textPrimary)),
                  content: Text('Are you sure you want to clear all offline data?', style: AppTypography.body(secondaryText)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppTypography.button(mutedText))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Clear', style: AppTypography.button(AppColors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(localDataSourceProvider).clearAllStations();
                ref.read(stationsProvider.notifier).loadStations();
                ref.read(favoritesProvider.notifier).load();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cache cleared', style: AppTypography.body(Colors.white))));
                }
              }
            },
          ),
          const SizedBox(height: 32),
          Text('About', style: AppTypography.sectionTitle(textPrimary)),
          const SizedBox(height: 16),
          _buildTile(
            icon: Icons.info_outline_rounded,
            title: 'About App',
            cardBg: cardBg,
            textPrimary: textPrimary,
            mutedText: mutedText,
            secondaryBg: secondaryBg,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(children: [const Icon(Icons.eco_rounded, color: AppColors.primaryAccent), const SizedBox(width: 12), Text('Air Quality Monitor', style: AppTypography.cardTitle(textPrimary))]),
                  content: Text(AppStrings.aboutDescription, style: AppTypography.body(secondaryText)),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: AppTypography.button(AppColors.primaryAccent)))],
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            cardBg: cardBg,
            textPrimary: textPrimary,
            mutedText: mutedText,
            secondaryBg: secondaryBg,
            onTap: () {
              // Open privacy policy
            },
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
}
