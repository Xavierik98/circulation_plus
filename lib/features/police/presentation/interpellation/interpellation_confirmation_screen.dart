import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/widgets/premium_button.dart';

class InterpellationConfirmationScreen extends StatefulWidget {
  const InterpellationConfirmationScreen({super.key});

  @override
  State<InterpellationConfirmationScreen> createState() =>
      _InterpellationConfirmationScreenState();
}

class _InterpellationConfirmationScreenState
    extends State<InterpellationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(const Duration(milliseconds: 300), () => _checkController.forward());
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Success animation
              _buildSuccessAnimation(),

              const SizedBox(height: 32),

              Text(
                'Interpellation\nenregistrée',
                style: AppTextStyles.displaySmall.copyWith(height: 1.2),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: 12),

              Text(
                'L\'amende a été émise et le conducteur\na été notifié.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 32),

              // Reference card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const _ConfirmRow(label: 'Référence', value: 'CP-2024-002847'),
                    const Divider(height: 20, color: AppColors.divider),
                    const _ConfirmRow(label: 'Conducteur', value: 'Thierry Nguesso'),
                    const Divider(height: 20, color: AppColors.divider),
                    const _ConfirmRow(label: 'Véhicule', value: 'BZV-4521-A'),
                    const Divider(height: 20, color: AppColors.divider),
                    const _ConfirmRow(
                        label: 'Montant',
                        value: '50 000 FCFA',
                        valueColor: AppColors.primary),
                    const Divider(height: 20, color: AppColors.divider),
                    const _ConfirmRow(label: 'Délai', value: '30 jours'),
                    const Divider(height: 20, color: AppColors.divider),
                    _ConfirmRow(
                      label: 'Horodatage',
                      value: _formatNow(),
                      valueStyle: AppTextStyles.mono.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1000.ms),

              const SizedBox(height: 20),

              // Notification confirmation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SMS + notification envoyés au +242 06 789 0123',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1100.ms),

              const Spacer(),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Imprimer',
                      icon: Icons.print_outlined,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PremiumButton(
                      label: 'Nouvelle interpellation',
                      icon: Icons.add_rounded,
                      onPressed: () => context.go('/police'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1200.ms),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return AnimatedBuilder(
      animation: _checkController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120 + _checkController.value * 20,
              height: 120 + _checkController.value * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.05 * (1 - _checkController.value)),
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
              ),
            ),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.successGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Transform.scale(
                scale: _checkController.value,
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year} '
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  const _ConfirmRow({required this.label, required this.value, this.valueColor, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ??
                AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

