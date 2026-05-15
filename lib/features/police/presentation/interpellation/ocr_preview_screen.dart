import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/driver_model.dart';
import '../../../../shared/models/vehicle_model.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_card.dart';

class OcrPreviewScreen extends StatelessWidget {
  const OcrPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverModel.mockDriver;
    final vehicle = VehicleModel.mockVehicle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vérification des données', style: AppTextStyles.titleSmall),
            Text('Étape 2 sur 5 — Aperçu OCR', style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.4,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // OCR confidence badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Extraction OCR — Confiance 97.3%',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 20),

            // Driver info card
            _buildSectionHeader('Informations conducteur', Icons.person_outline_rounded),
            const SizedBox(height: 10),
            PremiumCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${driver.firstName[0]}${driver.lastName[0]}',
                            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.fullName, style: AppTextStyles.titleMedium),
                            const SizedBox(height: 4),
                            _OcrField(label: 'N° Permis', value: driver.licenseNumber),
                          ],
                        ),
                      ),
                      _PointsIndicator(points: driver.remainingPoints, max: driver.totalPoints),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  const _OcrField(
                    label: 'Date de naissance',
                    value: '15/04/1988',
                  ),
                  const SizedBox(height: 8),
                  _OcrField(label: 'Adresse', value: driver.address),
                  const SizedBox(height: 8),
                  const _OcrField(label: 'Catégorie', value: 'Permis B'),
                  const SizedBox(height: 8),
                  const _OcrField(
                    label: 'Validité',
                    value: '20/06/2025',
                    valueColor: AppColors.warning,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

            const SizedBox(height: 20),

            // Vehicle info card
            _buildSectionHeader('Informations véhicule', Icons.directions_car_outlined),
            const SizedBox(height: 10),
            PremiumCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                            color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.brand} ${vehicle.model}',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            _PlateChip(plate: vehicle.plate),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  _OcrField(label: 'Propriétaire', value: vehicle.ownerName),
                  const SizedBox(height: 8),
                  _OcrField(label: 'Couleur', value: vehicle.color),
                  const SizedBox(height: 8),
                  _OcrField(label: 'Année', value: '${vehicle.year}'),
                  const SizedBox(height: 8),
                  const _OcrField(
                    label: 'Carte grise',
                    value: 'Valide jusqu\'au 12/08/2025',
                    valueColor: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _OcrField(
                    label: 'Assurance',
                    value: vehicle.hasInsurance ? 'Valide' : 'NON ASSURÉ',
                    valueColor: vehicle.hasInsurance ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 20),

            // Warning if any
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attention — Permis expirant bientôt',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Le permis de conduire expire le 20/06/2025. Le conducteur dispose de ${driver.remainingPoints}/${driver.totalPoints} points.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            PremiumButton(
              label: 'Confirmer et continuer',
              icon: Icons.check_rounded,
              onPressed: () => context.push('/police/infractions'),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 12),

            GhostButton(
              label: 'Modifier les données manuellement',
              icon: Icons.edit_outlined,
              onPressed: () {},
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

class _OcrField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _OcrField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PointsIndicator extends StatelessWidget {
  final int points;
  final int max;
  const _PointsIndicator({required this.points, required this.max});

  Color get _color {
    final ratio = points / max;
    if (ratio > 0.6) return AppColors.success;
    if (ratio > 0.3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: points / max,
                strokeWidth: 3,
                backgroundColor: AppColors.surfaceVariant,
                color: _color,
              ),
            ),
            Text(
              '$points',
              style: AppTextStyles.labelSmall.copyWith(color: _color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('points', style: AppTextStyles.caption),
      ],
    );
  }
}

class _PlateChip extends StatelessWidget {
  final String plate;
  const _PlateChip({required this.plate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGlow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(plate, style: AppTextStyles.mono.copyWith(fontSize: 12)),
    );
  }
}
