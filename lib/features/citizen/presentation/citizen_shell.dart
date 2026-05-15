import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CitizenShell extends StatelessWidget {
  final Widget child;
  const CitizenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.startsWith('/citizen/notifications')) selectedIndex = 1;
    if (location.startsWith('/citizen/license')) selectedIndex = 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _CitizenNavBar(selectedIndex: selectedIndex),
    );
  }
}

class _CitizenNavBar extends StatelessWidget {
  final int selectedIndex;
  const _CitizenNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.congoGreen.withValues(alpha: 0.4), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isSelected: selectedIndex == 0,
                onTap: () => context.go('/citizen'),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                label: 'Alertes',
                isSelected: selectedIndex == 1,
                onTap: () => context.go('/citizen/notifications'),
                badge: 2,
              ),
              _NavItem(
                icon: Icons.credit_card_rounded,
                label: 'Permis',
                isSelected: selectedIndex == 2,
                onTap: () => context.go('/citizen/license'),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Paramètres',
                isSelected: selectedIndex == 3,
                onTap: () => context.push('/citizen/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22,
                      color: isSelected ? AppColors.success : AppColors.textTertiary),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Center(
                          child: Text('$badge',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.success : AppColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
