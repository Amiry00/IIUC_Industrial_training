import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../providers/providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final textSecondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: AppTypography.sectionTitle(textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: AppColors.primaryAccent),
            tooltip: 'Mark all as read',
            onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context, ref, cardBg, textPrimary, textSecondary),
          ),
        ],
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: mutedText),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTypography.body(mutedText)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: ValueKey(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: AppColors.error,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(notificationsProvider.notifier).delete(notif.id);
                },
                child: InkWell(
                  onTap: () {
                    if (!notif.isRead) {
                      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                    }
                  },
                  child: Container(
                    color: notif.isRead ? Colors.transparent : AppColors.primaryAccent.withOpacity(0.05),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getIconColor(notif.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(notif.type), color: _getIconColor(notif.type)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: AppTypography.cardTitle(textPrimary).copyWith(
                                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notif.body, style: AppTypography.body(textSecondary)),
                              const SizedBox(height: 8),
                              Text(DateFormatter.formatDateWithTime(notif.timestamp), style: AppTypography.label(mutedText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
        error: (e, _) => Center(child: Text(e.toString(), style: AppTypography.body(AppColors.error))),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'favorite':
        return Icons.favorite_border_rounded;
      case 'reminder':
        return Icons.access_time_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'alert':
        return AppColors.error;
      case 'favorite':
        return AppColors.aqiModerate;
      case 'reminder':
        return AppColors.primaryAccent;
      default:
        return AppColors.mutedText;
    }
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref, Color cardBg, Color textPrimary, Color textSecondary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Clear All', style: AppTypography.cardTitle(textPrimary)),
        content: Text('Are you sure you want to delete all notifications?', style: AppTypography.body(textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.button(textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: AppTypography.button(AppColors.error)),
          ),
        ],
      ),
    );
  }
}
