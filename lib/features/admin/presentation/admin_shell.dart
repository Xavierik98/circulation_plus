import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/pnc_badge.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    int selectedIndex = 0;
    if (location.startsWith('/admin/map')) selectedIndex = 1;
    if (location.startsWith('/admin/officers')) selectedIndex = 2;
    if (location.startsWith('/admin/revenue')) selectedIndex = 3;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _AdminRailNav(selectedIndex: selectedIndex),
            const VerticalDivider(width: 1, color: AppColors.divider),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _AdminBottomNav(selectedIndex: selectedIndex),
    );
  }
}

class _AdminRailNav extends StatelessWidget {
  final int selectedIndex;
  const _AdminRailNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, 'Tableau de bord', '/admin'),
      (Icons.map_outlined, 'Carte', '/admin/map'),
      (Icons.badge_outlined, 'Agents', '/admin/officers'),
      (Icons.account_balance_outlined, 'Revenus', '/admin/revenue'),
    ];

    return Container(
      width: 72,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const PncBadge(size: 46, showGlow: false),
            const SizedBox(height: 6),
            const Text('ADMIN', style: TextStyle(color: AppColors.gold, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Divider(height: 1, color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            ...items.asMap().entries.map((entry) {
              final (icon, _, route) = entry.value;
              final isSelected = selectedIndex == entry.key;
              return GestureDetector(
                onTap: () => context.go(route),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.info.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon,
                      size: 22,
                      color: isSelected ? AppColors.info : AppColors.textTertiary),
                ),
              );
            }),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/admin/settings'),
              child: Container(
                width: 52, height: 52,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int selectedIndex;
  const _AdminBottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, 'Analytics', '/admin'),
      (Icons.map_outlined, 'Carte', '/admin/map'),
      (Icons.badge_outlined, 'Agents', '/admin/officers'),
      (Icons.account_balance_outlined, 'Revenus', '/admin/revenue'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final (icon, label, route) = entry.value;
              final isSelected = selectedIndex == entry.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(route),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.info.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 22,
                            color: isSelected ? AppColors.info : AppColors.textTertiary),
                        const SizedBox(height: 4),
                        Text(label,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected ? AppColors.info : AppColors.textTertiary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
