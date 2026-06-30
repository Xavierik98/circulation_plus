import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _StitchColors {
  static const Color primary = Color(0xFF023020);
  static const Color secondaryContainer = Color(0xFFfcdf4b);
  static const Color onSecondaryContainer = Color(0xFF023020);
  static const Color surface = Colors.white;
  static const Color onSurfaceVariant = Color(0xFF4B5563);
  static const Color outlineVariant = Color(0xFFE5E7EB);
}

class PoliceShell extends StatelessWidget {
  final Widget child;
  const PoliceShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.startsWith('/police/scan')) selectedIndex = 1;
    if (location.startsWith('/police/history')) selectedIndex = 2;
    if (location.startsWith('/police/settings') || location.startsWith('/police/profile')) selectedIndex = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: child,
      bottomNavigationBar: _PremiumNavBar(selectedIndex: selectedIndex),
    );
  }
}

class _PremiumNavBar extends StatelessWidget {
  final int selectedIndex;
  const _PremiumNavBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _StitchColors.surface,
        border: Border(top: BorderSide(color: _StitchColors.outlineVariant, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: selectedIndex == 0,
                onTap: () => context.go('/police'),
              ),
              _NavItem(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                isSelected: selectedIndex == 1,
                onTap: () => context.push('/police/scan'),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Historique',
                isSelected: selectedIndex == 2,
                onTap: () => context.go('/police/history'),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isSelected: selectedIndex == 3,
                onTap: () => context.push('/police/settings'),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? _StitchColors.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? _StitchColors.onSecondaryContainer : _StitchColors.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _StitchColors.onSecondaryContainer : _StitchColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
