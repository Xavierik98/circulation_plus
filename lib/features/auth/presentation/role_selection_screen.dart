import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';

/// Écran de sélection du rôle — design Stitch "Sélection du Rôle".
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // TopAppBar
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: StitchColors.surface,
                    border: Border(bottom: BorderSide(color: StitchColors.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: StitchColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Circulation+',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: StitchColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Hero
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: StitchColors.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.verified_user, color: Colors.white, size: 40),
                          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7)),
                          const SizedBox(height: 16),
                          Text(
                            'Bienvenue',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: StitchColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Veuillez sélectionner votre profil pour accéder aux services officiels.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 40),

                          _RoleCard(
                            icon: Icons.badge,
                            accent: StitchColors.primary,
                            iconBg: StitchColors.primaryContainer.withValues(alpha: 0.1),
                            title: 'POLICE',
                            subtitle: 'Accès agents de la DGPN',
                            onTap: () => context.push('/login/police'),
                            delay: 0,
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            icon: Icons.person,
                            accent: StitchColors.secondary,
                            iconBg: StitchColors.secondaryContainer.withValues(alpha: 0.2),
                            title: 'CITOYEN',
                            subtitle: 'Consultation et paiement',
                            onTap: () => context.push('/login/citizen'),
                            delay: 100,
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            icon: Icons.settings,
                            accent: StitchColors.tertiary,
                            iconBg: StitchColors.tertiaryContainer.withValues(alpha: 0.1),
                            title: 'ADMIN',
                            subtitle: 'Gestion et statistiques',
                            onTap: () => context.push('/login/admin'),
                            delay: 200,
                          ),

                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 32, height: 4, decoration: BoxDecoration(color: StitchColors.primary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 16),
                              Container(width: 32, height: 4, decoration: BoxDecoration(color: StitchColors.secondary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 16),
                              Container(width: 32, height: 4, decoration: BoxDecoration(color: StitchColors.tertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'RÉPUBLIQUE DU CONGO • MINISTÈRE DE L\'INTÉRIEUR',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: StitchColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sécurité • Légalité • Proximité',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: StitchColors.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bandeau tricolore Congo
                Row(
                  children: [
                    Expanded(child: Container(height: 4, color: StitchColors.primary)),
                    Expanded(child: Container(height: 4, color: StitchColors.secondary)),
                    Expanded(child: Container(height: 4, color: StitchColors.tertiary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int delay;

  const _RoleCard({
    required this.icon,
    required this.accent,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: StitchColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StitchColors.outlineVariant),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              // Barre d'accent gauche
              Container(width: 6, height: 64, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)))),
              const SizedBox(width: 10),
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: StitchColors.outlineVariant),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}
