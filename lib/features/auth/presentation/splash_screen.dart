import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/pnc_badge.dart';
import '../providers/auth_provider.dart';

/// Écran de démarrage — aligné sur le thème clair Stitch (vert PNC).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        context.go(switch (auth.role) {
          UserRole.police => '/police',
          UserRole.citizen => '/citizen',
          UserRole.admin => '/admin',
          UserRole.none => '/role',
        });
      } else {
        context.go('/role');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: Stack(
        children: [
          // Glows ambiants
          Positioned.fill(child: CustomPaint(painter: _SplashBackgroundPainter())),

          // Contenu principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoMark(),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Circulation',
                      style: GoogleFonts.inter(fontSize: 38, fontWeight: FontWeight.w800, color: StitchColors.onSurface, letterSpacing: -1.5),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 600.ms),
                    Text(
                      '+',
                      style: GoogleFonts.inter(fontSize: 38, fontWeight: FontWeight.w800, color: StitchColors.primary, letterSpacing: -1.5),
                    ).animate().fadeIn(delay: 900.ms, duration: 400.ms).scale(begin: const Offset(0.3, 0.3), delay: 900.ms, duration: 400.ms),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  AppConstants.country.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: StitchColors.primary, letterSpacing: 4),
                ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  'Infrastructure Nationale de Contrôle Routier',
                  style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1300.ms, duration: 500.ms),

                const SizedBox(height: 60),

                _buildLoadingIndicator(),
              ],
            ),
          ),

          // Filigrane bas
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(width: 48, height: 1, color: StitchColors.outlineVariant).animate().fadeIn(delay: 1500.ms),
                const SizedBox(height: 12),
                Text(
                  AppConstants.dgst,
                  style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1600.ms),
                const SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant),
                ).animate().fadeIn(delay: 1700.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoMark() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130 + t * 22,
              height: 130 + t * 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: StitchColors.primary.withValues(alpha: 0.18 * (1 - t)), width: 1),
              ),
            ),
            Container(
              width: 116 + t * 10,
              height: 116 + t * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: StitchColors.primary.withValues(alpha: 0.12 * (1 - t)), width: 1),
              ),
            ),
            child!,
          ],
        );
      },
      child: const PncBadge(size: 108, showGlow: true),
    ).animate().fadeIn(duration: 700.ms).scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.easeOutBack);
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 120,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: StitchColors.surfaceContainerHigh,
              color: StitchColors.primary,
              minHeight: 2,
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 1800.ms);
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Glow vert (primaire) en haut-gauche
    paint.shader = RadialGradient(
      colors: [StitchColors.primary.withValues(alpha: 0.08), Colors.transparent],
      radius: 0.7,
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.1, size.height * 0.2), radius: size.width * 0.65));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), size.width * 0.65, paint);

    // Glow jaune (secondaire) au centre
    paint.shader = RadialGradient(
      colors: [StitchColors.secondaryContainer.withValues(alpha: 0.10), Colors.transparent],
      radius: 0.5,
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.45), radius: size.width * 0.5));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), size.width * 0.5, paint);

    // Glow rouge (tertiaire) en bas-droite — très subtil
    paint.shader = RadialGradient(
      colors: [StitchColors.tertiary.withValues(alpha: 0.05), Colors.transparent],
      radius: 0.6,
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.9, size.height * 0.8), radius: size.width * 0.5));
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), size.width * 0.5, paint);

    // Bandeau diagonal drapeau Congo — discret
    const stripeColors = [StitchColors.congoGreen, StitchColors.congoYellow, StitchColors.congoRed];
    const stripeWidth = 3.0;
    const gap = 7.0;
    for (int i = 0; i < 3; i++) {
      final offset = size.width * 0.88 + i * (stripeWidth + gap);
      final linePaint = Paint()
        ..color = stripeColors[i].withValues(alpha: 0.15)
        ..strokeWidth = stripeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(offset, 0), Offset(offset - size.height * 0.5, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
