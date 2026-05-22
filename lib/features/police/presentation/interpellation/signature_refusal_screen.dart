import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/interpellation_state.dart';
import '../../../../shared/widgets/premium_button.dart';

class SignatureRefusalScreen extends ConsumerStatefulWidget {
  const SignatureRefusalScreen({super.key});

  @override
  ConsumerState<SignatureRefusalScreen> createState() =>
      _SignatureRefusalScreenState();
}

class _SignatureRefusalScreenState
    extends ConsumerState<SignatureRefusalScreen> {
  final Set<DocumentSaisi> _selected = {};
  // Photo prise pour chaque document saisi : DocumentSaisi → chemin du fichier
  final Map<DocumentSaisi, String> _photos = {};
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto(DocumentSaisi doc) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (photo != null) {
        setState(() => _photos[doc] = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'appareil photo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final interpellation = ref.watch(interpellationProvider);

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
            Text('Refus de signature', style: AppTextStyles.titleSmall),
            Text('Saisie de documents', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Alerte refus ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Le conducteur refuse de signer',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Conformément à l\'article du code de la route, '
                          'vous pouvez procéder à la saisie des documents '
                          'du véhicule. Une convocation sera automatiquement '
                          'générée.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // ── Conducteur concerné ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          interpellation.driverName.isNotEmpty
                              ? interpellation.driverName
                              : 'Conducteur',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        Text(
                          interpellation.vehiclePlate.isNotEmpty
                              ? interpellation.vehiclePlate
                              : '— plaque non renseignée —',
                          style: AppTextStyles.mono
                              .copyWith(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // ── Documents à saisir ────────────────────────────────
            Text('Documents saisis', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Cochez les documents récupérés. '
              'La liste figure dans le procès-verbal.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),

            ...DocumentSaisi.values.asMap().entries.map((entry) {
              final doc = entry.value;
              final isSelected = _selected.contains(doc);
              final photoPath = _photos[doc];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.error.withValues(alpha: 0.07)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.error.withValues(alpha: 0.4)
                          : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── Ligne principale : sélection ──
                      GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selected.remove(doc);
                            _photos.remove(doc);
                          } else {
                            _selected.add(doc);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Text(doc.icon,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  doc.label,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Indicateur photo prise
                              if (isSelected && photoPath != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.photo_camera,
                                          size: 11,
                                          color: AppColors.success),
                                      const SizedBox(width: 3),
                                      Text('Photo',
                                          style:
                                              AppTextStyles.caption.copyWith(
                                            color: AppColors.success,
                                            fontSize: 10,
                                          )),
                                    ],
                                  ),
                                ),
                              AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.error
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.error
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Bouton photo (visible uniquement si coché) ──
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              14, 0, 14, 12),
                          child: Row(
                            children: [
                              // Miniature photo si prise
                              if (photoPath != null)
                                GestureDetector(
                                  onTap: () =>
                                      _takePhoto(doc),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Image.file(
                                      File(photoPath),
                                      width: 56,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (photoPath != null)
                                const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _takePhoto(doc),
                                  icon: Icon(
                                    photoPath != null
                                        ? Icons
                                            .camera_alt_rounded
                                        : Icons
                                            .camera_alt_outlined,
                                    size: 15,
                                  ),
                                  label: Text(
                                    photoPath != null
                                        ? 'Reprendre la photo'
                                        : 'Photographier le document',
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: photoPath !=
                                            null
                                        ? AppColors.success
                                        : AppColors.textTertiary,
                                    side: BorderSide(
                                      color: photoPath != null
                                          ? AppColors.success
                                              .withValues(
                                                  alpha: 0.5)
                                          : AppColors.cardBorder,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
                    .animate(
                        delay: Duration(
                            milliseconds: 150 + entry.key * 50))
                    .fadeIn(duration: 250.ms)
                    .slideX(begin: 0.05),
              );
            }),

            const SizedBox(height: 24),

            // ── Convocation automatique ───────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convocation automatique',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.warning),
                        ),
                        Text(
                          'Une convocation sera générée et envoyée au '
                          'conducteur dans les 7 jours. Les documents saisis '
                          'seront restitués après paiement de l\'amende au '
                          'Trésor public.',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // ── Boutons ───────────────────────────────────────────
            PremiumButton(
              label: 'Enregistrer et générer la convocation',
              icon: Icons.send_outlined,
              onPressed: () {
                ref
                    .read(interpellationProvider.notifier)
                    .setSignatureRefused(
                      refused: true,
                      documentsSeizes: _selected.toList(),
                    );
                context.go('/police/confirmation');
              },
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Retour — essayer à nouveau'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 650.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
