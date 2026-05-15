import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../shared/models/fine_model.dart';
import '../../shared/models/officer_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
    this.fontSize,
  });

  factory StatusBadge.fromFineStatus(FineStatus status) {
    switch (status) {
      case FineStatus.pending:
        return const StatusBadge(label: 'En attente', color: AppColors.statusPending);
      case FineStatus.paid:
        return const StatusBadge(label: 'Payé', color: AppColors.statusPaid);
      case FineStatus.overdue:
        return const StatusBadge(label: 'En retard', color: AppColors.statusOverdue);
      case FineStatus.contested:
        return const StatusBadge(label: 'Contesté', color: AppColors.statusContested);
      case FineStatus.cancelled:
        return const StatusBadge(label: 'Annulé', color: AppColors.statusCancelled);
    }
  }

  factory StatusBadge.fromOfficerStatus(OfficerStatus status) {
    switch (status) {
      case OfficerStatus.active:
        return const StatusBadge(label: 'En service', color: AppColors.success);
      case OfficerStatus.inactive:
        return const StatusBadge(label: 'Hors service', color: AppColors.textTertiary);
      case OfficerStatus.suspended:
        return const StatusBadge(label: 'Suspendu', color: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: fontSize ?? 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PointsBadge extends StatelessWidget {
  final int points;
  final int maxPoints;

  const PointsBadge({super.key, required this.points, required this.maxPoints});

  Color get _color {
    final ratio = points / maxPoints;
    if (ratio > 0.6) return AppColors.success;
    if (ratio > 0.3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '$points/$maxPoints pts',
            style: AppTextStyles.labelSmall.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
