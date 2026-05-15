import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/notification_model.dart';

class CitizenNotificationsScreen extends StatelessWidget {
  const CitizenNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationModel.mockCitizenNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Notifications', style: AppTextStyles.titleMedium),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Tout lire', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = notifications[i];
          return _NotifCard(n: n, onTap: () {
            if (n.actionId != null) {
              context.push('/citizen/fine/${n.actionId}');
            }
          })
              .animate(delay: Duration(milliseconds: i * 80))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05);
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel n;
  final VoidCallback? onTap;
  const _NotifCard({required this.n, this.onTap});

  Color get _color => switch (n.type) {
    NotificationType.fine => AppColors.error,
    NotificationType.payment => AppColors.success,
    NotificationType.alert => AppColors.warning,
    NotificationType.system => AppColors.primary,
    NotificationType.info => AppColors.info,
  };

  IconData get _icon => switch (n.type) {
    NotificationType.fine => Icons.gavel_rounded,
    NotificationType.payment => Icons.check_circle_rounded,
    NotificationType.alert => Icons.warning_amber_rounded,
    NotificationType.system => Icons.settings_rounded,
    NotificationType.info => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.isRead ? AppColors.cardBorder : _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: n.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            )),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: n.isRead ? AppColors.textDisabled : AppColors.textTertiary,
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(_timeAgo(n.createdAt), style: AppTextStyles.caption),
                      if (n.actionId != null) ...[
                        const SizedBox(width: 8),
                        Text('Voir', style: AppTextStyles.caption.copyWith(color: _color)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
