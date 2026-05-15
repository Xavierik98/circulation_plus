import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

class LicenseStatusScreen extends StatelessWidget {
  const LicenseStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const points = 9;
    const maxPoints = 12;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Statut du permis', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // License card mock
            _buildLicenseCard(),

            const SizedBox(height: 24),

            // Points gauge
            _buildPointsGauge(points, maxPoints),

            const SizedBox(height: 24),

            // Status details
            _buildStatusDetails(),

            const SizedBox(height: 24),

            // Points history
            _buildPointsHistory(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard() {
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
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text('PERMIS DE CONDUIRE',
                          style: AppTextStyles.overline.copyWith(color: AppColors.primary, fontSize: 9)),
                    ),
                    const Spacer(),
                    Text('RÉPUBLIQUE DU CONGO',
                        style: AppTextStyles.overline.copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 8)),
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
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NGUESSO', style: AppTextStyles.titleSmall.copyWith(color: Colors.white, letterSpacing: 2)),
                          Text('Thierry Jean', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                          const SizedBox(height: 4),
                          Text('Né le 15/04/1988', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.5))),
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
                const Row(
                  children: [
                    _LicenseField(label: 'N°', value: 'BZV-2024-047821'),
                    SizedBox(width: 20),
                    _LicenseField(label: 'Cat.', value: 'B'),
                    SizedBox(width: 20),
                    _LicenseField(label: 'Exp.', value: '20/06/2025'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildPointsGauge(int points, int maxPoints) {
    final color = points > 8
        ? AppColors.success
        : points > 4
            ? AppColors.warning
            : AppColors.error;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Capital de points', style: AppTextStyles.titleMedium),
              const Spacer(),
              Text('$points / $maxPoints', style: AppTextStyles.titleMedium.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: points / maxPoints),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: AppColors.surfaceVariant,
                  color: color,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 pts — Annulation', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              Text('12 pts — Maximum', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    points > 8
                        ? 'Votre permis est en bon état. Continuez à conduire prudemment.'
                        : 'Attention: ${maxPoints - points} points retirés. Soyez prudent.',
                    style: AppTextStyles.bodySmall.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatusDetails() {
    return const PremiumCard(
      child: Column(
        children: [
          _StatusDetailRow(label: 'Catégorie', value: 'Permis B', icon: Icons.credit_card_rounded),
          Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(label: 'Émis le', value: '20/06/2015', icon: Icons.calendar_today_outlined),
          Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(label: 'Expire le', value: '20/06/2025', icon: Icons.event_outlined, valueColor: AppColors.warning),
          Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(label: 'Statut', value: 'VALIDE', icon: Icons.verified_rounded, valueColor: AppColors.success),
          Divider(height: 20, color: AppColors.divider),
          _StatusDetailRow(label: 'Infractions totales', value: '3', icon: Icons.gavel_rounded, valueColor: AppColors.warning),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPointsHistory() {
    final history = [
      ('Excès de vitesse', '-2 pts', DateTime.now().subtract(const Duration(days: 5)), AppColors.error),
      ('Téléphone au volant', '-2 pts', DateTime.now().subtract(const Duration(days: 45)), AppColors.error),
      ('Non-port ceinture', '-1 pt', DateTime.now().subtract(const Duration(days: 75)), AppColors.warning),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historique des retraits', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: history.asMap().entries.map((entry) {
              final (label, pts, date, color) = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_downward_rounded, color: color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                              Text('${date.day}/${date.month}/${date.year}', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Text(pts, style: AppTextStyles.labelSmall.copyWith(color: color)),
                      ],
                    ),
                  ),
                  if (entry.key < history.length - 1)
                    const Divider(height: 1, color: AppColors.divider, indent: 62),
                ],
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
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
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }
}

class _StatusDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _StatusDetailRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
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
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmallQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    final cell = size.width / 5;
    const pattern = [[1,1,1,0,1],[1,0,1,0,0],[1,1,1,0,1],[0,0,0,1,0],[1,0,1,1,1]];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (pattern[r][c] == 1) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
