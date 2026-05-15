import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/pnc_badge.dart';
import '../providers/auth_provider.dart';

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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient glow background
          Positioned.fill(
            child: CustomPaint(painter: _SplashBackgroundPainter()),
          ),

          // Grid lines overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                _buildLogoMark(),

                const SizedBox(height: 32),

                // App name
                Text(
                  'Circulation',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: -2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 600.ms),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                        letterSpacing: -2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 400.ms)
                        .scale(begin: const Offset(0.3, 0.3), delay: 900.ms, duration: 400.ms),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  AppConstants.country.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                    fontSize: 11,
                  ),
                ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  'Infrastructure Nationale de Contrôle Routier',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1300.ms, duration: 500.ms),

                const SizedBox(height: 60),

                // Loading indicator
                _buildLoadingIndicator(),
              ],
            ),
          ),

          // Bottom watermark
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 1,
                  color: AppColors.divider,
                ).animate().fadeIn(delay: 1500.ms),
                const SizedBox(height: 12),
                Text(
                  AppConstants.dgst,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1600.ms),
                const SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
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
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring — gold
            Container(
              width: 130 + _pulseController.value * 22,
              height: 130 + _pulseController.value * 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.12 * (1 - _pulseController.value)),
                  width: 1,
                ),
              ),
            ),
            // Second pulse ring
            Container(
              width: 116 + _pulseController.value * 10,
              height: 116 + _pulseController.value * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.08 * (1 - _pulseController.value)),
                  width: 1,
                ),
              ),
            ),
            // PNC Badge
            child!,
          ],
        );
      },
      child: const PncBadge(size: 108, showGlow: true),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.easeOutBack);
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1800.ms);
  }
}


class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-left: gold glow (police badge warmth)
    paint.shader = RadialGradient(
      colors: [AppColors.gold.withValues(alpha: 0.07), Colors.transparent],
      radius: 0.7,
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.1, size.height * 0.25),
      radius: size.width * 0.65,
    ));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.25), size.width * 0.65, paint);

    // Center glow: deep blue
    paint.shader = RadialGradient(
      colors: [AppColors.primary.withValues(alpha: 0.06), Colors.transparent],
      radius: 0.5,
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.42),
      radius: size.width * 0.5,
    ));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.42), size.width * 0.5, paint);

    // Bottom-right: Congo green hint
    paint.shader = RadialGradient(
      colors: [AppColors.congoGreen.withValues(alpha: 0.04), Colors.transparent],
      radius: 0.6,
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.9, size.height * 0.78),
      radius: size.width * 0.5,
    ));
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.78), size.width * 0.5, paint);

    // Congo flag diagonal stripe — very subtle, bottom-left to top-right
    const stripeColors = [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed];
    const stripeWidth = 3.0;
    const gap = 7.0;
    for (int i = 0; i < 3; i++) {
      final offset = size.width * 0.88 + i * (stripeWidth + gap);
      final linePaint = Paint()
        ..color = stripeColors[i].withValues(alpha: 0.18)
        ..strokeWidth = stripeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset - size.height * 0.5, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
