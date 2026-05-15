import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/pnc_badge.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackgroundPainter())),

          // Congo flag top accent bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),

                  // Header with PNC badge
                  Row(
                    children: [
                      const PncBadge(size: 52, showGlow: false),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.congoGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                'POLICE NATIONALE DU CONGO',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gold,
                                  letterSpacing: 1.5,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),

                  const SizedBox(height: 48),

                  Text(
                    'Accès sécurisé',
                    style: AppTextStyles.displaySmall.copyWith(
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),

                  Text(
                    'Sélectionnez votre profil pour accéder\nà la plateforme nationale.',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                  const SizedBox(height: 40),

                  // Police card — premium gold treatment
                  const _PoliceRoleCard(delay: 400),

                  const SizedBox(height: 14),

                  const _RoleCard(
                    role: 'citizen',
                    title: 'Citoyen',
                    subtitle: 'Amendes · Paiements · Permis de conduire',
                    icon: Icons.person_rounded,
                    gradient: LinearGradient(
                      colors: [AppColors.congoGreen, Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    accentColor: AppColors.congoGreen,
                    delay: 500,
                  ),

                  const SizedBox(height: 14),

                  const _RoleCard(
                    role: 'admin',
                    title: 'Administration',
                    subtitle: 'Analytique · Agents · Revenus nationaux',
                    icon: Icons.admin_panel_settings_rounded,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4338CA), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    accentColor: Color(0xFF6366F1),
                    delay: 600,
                  ),

                  const Spacer(),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 16, height: 1, color: AppColors.divider),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Container(width: 16, height: 1, color: AppColors.divider),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.ministry,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Connexion chiffrée TLS 1.3',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Police card with gold PNC treatment
class _PoliceRoleCard extends StatelessWidget {
  final int delay;
  const _PoliceRoleCard({required this.delay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/login/police'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1F45), Color(0xFF0A1428)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.policeBlue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // PNC Badge
            const PncBadge(size: 58, showGlow: false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Agent de Police',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'PNC',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contrôle routier · Interpellations · Terrain',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Congo flag strip
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 3,
                      width: 80,
                      decoration: const BoxDecoration(
                        gradient: AppColors.congoFlagGradient,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: delay), duration: 400.ms);
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final int delay;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/login/$role'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: delay), duration: 400.ms);
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Gold glow top-right
    paint.shader = RadialGradient(
      colors: [AppColors.gold.withValues(alpha: 0.06), Colors.transparent],
      radius: 0.7,
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.9, size.height * 0.08),
      radius: size.width * 0.6,
    ));
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.08), size.width * 0.6, paint);

    // Blue glow center-left
    paint.shader = RadialGradient(
      colors: [AppColors.primary.withValues(alpha: 0.05), Colors.transparent],
      radius: 0.8,
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.1, size.height * 0.55),
      radius: size.width * 0.55,
    ));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.55), size.width * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
