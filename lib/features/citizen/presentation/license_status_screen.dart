import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class LicenseStatusScreen extends ConsumerWidget {
  const LicenseStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final hasProfile = (auth.userName?.isNotEmpty ?? false) ||
        (auth.telephone?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Statut du permis', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration:
                const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildLicenseCard(auth),
            const SizedBox(height: 24),
            if (!hasProfile) ...[
              _buildCompleteProfileCta(context),
              const SizedBox(height: 24),
            ],
            _buildStatusDetails(auth),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard(AuthState auth) {
    final name = auth.userName ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final lastName =
        parts.isNotEmpty && parts.first.isNotEmpty ? parts.first.toUpperCase() : '—';
    final firstName =
        parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final phone = auth.telephone ?? '—';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1E3A), Color(0xFF162038)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CardPatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'PERMIS DE CONDUIRE',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.primary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'RÉPUBLIQUE DU CONGO',
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastName,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          if (firstName.isNotEmpty)
                            Text(
                              firstName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomPaint(painter: _SmallQrPainter()),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LicenseField(
                      label: 'Email',
                      value: auth.email?.isNotEmpty == true
                          ? auth.email!
                          : '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildCompleteProfileCta(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/citizen/profile'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil incomplet',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complétez votre profil pour afficher vos informations sur le permis.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatusDetails(AuthState auth) {
    return PremiumCard(
      child: Column(
        children: [
          _StatusDetailRow(
            label: 'Nom complet',
            value: auth.userName?.isNotEmpty == true ? auth.userName! : '—',
            icon: Icons.person_outline_rounded,
          ),
          const Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(
            label: 'Téléphone',
            value: auth.telephone?.isNotEmpty == true ? auth.telephone! : '—',
            icon: Icons.phone_outlined,
          ),
          const Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(
            label: 'Email',
            value: auth.email?.isNotEmpty == true ? auth.email! : '—',
            icon: Icons.email_outlined,
          ),
          const Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(
            label: 'Statut compte',
            value: auth.emailVerified ? 'VÉRIFIÉ' : 'EN ATTENTE',
            icon: Icons.verified_rounded,
            valueColor:
                auth.emailVerified ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _LicenseField extends StatelessWidget {
  final String label;
  final String value;
  const _LicenseField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 9, letterSpacing: 1)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatusDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _StatusDetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double i = -size.height; i < size.width; i += 30) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmallQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final cell = size.width / 5;
    const pattern = [
      [1, 1, 1, 0, 1],
      [1, 0, 1, 0, 0],
      [1, 1, 1, 0, 1],
      [0, 0, 0, 1, 0],
      [1, 0, 1, 1, 1],
    ];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (pattern[r][c] == 1) {
          canvas.drawRect(
              Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
