import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/interpellation_state.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/repositories.dart';

/// Écran de saisie/vérification des données du conducteur après scan.
/// Permis congolais (RC) — PAS de système de points.
class OcrPreviewScreen extends ConsumerStatefulWidget {
  const OcrPreviewScreen({super.key});

  @override
  ConsumerState<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends ConsumerState<OcrPreviewScreen> {
  final _formKey = GlobalKey<FormState>();

  // Conducteur
  final _nameCtrl    = TextEditingController();
  final _licCtrl     = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _dobCtrl     = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Véhicule
  final _plateCtrl  = TextEditingController();
  final _brandCtrl  = TextEditingController();
  final _modelCtrl  = TextEditingController();
  final _colorCtrl  = TextEditingController();

  // Documents
  bool _hasPermis    = true;
  bool _hasCarteGrise = true;
  bool _hasAssurance  = true;
  bool _hasControle   = true;
  bool _sansDocument  = false; // Le conducteur n'a AUCUN document

  bool _isConfirming = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir depuis l'état actuel (si un scan précédent a déjà alimenté)
    final s = ref.read(interpellationProvider);
    _nameCtrl.text  = s.driverName;
    _licCtrl.text   = s.driverLicense;
    _phoneCtrl.text = s.driverPhone;
    _plateCtrl.text = s.vehiclePlate;
    _brandCtrl.text = s.vehicleBrand;
    _modelCtrl.text = s.vehicleModel;
    _colorCtrl.text = s.vehicleColor;
    _hasPermis      = s.hasLicense;
    _hasCarteGrise  = s.hasCarteGrise;
    _hasAssurance   = s.hasAssurance;
    _hasControle    = s.hasControleTechnique;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _licCtrl.dispose(); _phoneCtrl.dispose();
    _dobCtrl.dispose();  _addressCtrl.dispose();
    _plateCtrl.dispose(); _brandCtrl.dispose();
    _modelCtrl.dispose(); _colorCtrl.dispose();
    super.dispose();
  }

  void _onSansDocumentToggle(bool v) {
    setState(() {
      _sansDocument = v;
      if (v) {
        _hasPermis     = false;
        _hasCarteGrise = false;
        _hasAssurance  = false;
        _hasControle   = false;
      }
    });
  }

  /// Recherche le conducteur + véhicule par numéro de plaque dans la BD.
  Future<void> _searchByPlate() async {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saisissez d\'abord le numéro de plaque'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _isSearching = true);
    try {
      final result = await DriverRepository().search(plate: plate);
      if (!mounted) return;

      // Résultats du backend : { driver: {...}, vehicle: {...}, fines: [...] }
      final driver = result['driver'] as Map<String, dynamic>?;
      final vehicle = result['vehicle'] as Map<String, dynamic>?;

      if (driver == null && vehicle == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucun conducteur trouvé pour cette plaque'),
          backgroundColor: AppColors.warning,
        ));
        return;
      }

      setState(() {
        if (driver != null) {
          final prenom = driver['prenom'] as String? ?? '';
          final nom = driver['nom'] as String? ?? '';
          _nameCtrl.text = '$prenom $nom'.trim();
          _licCtrl.text = driver['numeroPermis'] as String? ?? _licCtrl.text;
          _phoneCtrl.text = driver['telephone'] as String? ?? _phoneCtrl.text;
        }
        if (vehicle != null) {
          _brandCtrl.text = vehicle['marque'] as String? ?? _brandCtrl.text;
          _modelCtrl.text = vehicle['modele'] as String? ?? _modelCtrl.text;
          _colorCtrl.text = vehicle['couleur'] as String? ?? _colorCtrl.text;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Informations pré-remplies depuis la base de données'),
        ]),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Plaque non trouvée en base — saisissez manuellement'),
          backgroundColor: AppColors.textTertiary,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isConfirming = true);

    final notifier = ref.read(interpellationProvider.notifier);

    notifier.updateDriver(
      name:       _nameCtrl.text.trim(),
      license:    _licCtrl.text.trim(),
      hasLicense: _hasPermis,
      phone:      _phoneCtrl.text.trim(),
    );
    notifier.updateVehicle(
      plate:               _plateCtrl.text.trim().toUpperCase(),
      brand:               _brandCtrl.text.trim(),
      model:               _modelCtrl.text.trim(),
      color:               _colorCtrl.text.trim(),
      hasCarteGrise:       _hasCarteGrise,
      hasAssurance:        _hasAssurance,
      hasControleTechnique: _hasControle,
    );

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() => _isConfirming = false);
      context.push('/police/location');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Infos conducteur & véhicule', style: AppTextStyles.titleSmall),
            Text('Étape 2 sur 5 — Saisie manuelle', style: AppTextStyles.caption),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Photo du document (si capturée)
              Builder(builder: (ctx) {
                final scanPath =
                    ref.watch(interpellationProvider).scanImagePath;
                if (scanPath == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(scanPath),
                          width: 100,
                          height: 65,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Document scanné',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.success)),
                            const SizedBox(height: 4),
                            Text(
                              'Vérifiez et complétez les champs ci-dessous en vous basant sur le document.',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn();
              }),

              // Bandeau RC
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Permis de conduire — République du Congo (RC) · Saisissez les informations du document présenté.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // ── Option : conducteur sans document ─────────────────────────
              GestureDetector(
                onTap: () => _onSansDocumentToggle(!_sansDocument),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _sansDocument
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _sansDocument
                          ? AppColors.error.withValues(alpha: 0.5)
                          : AppColors.cardBorder,
                      width: _sansDocument ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _sansDocument
                              ? AppColors.error
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _sansDocument
                                ? AppColors.error
                                : AppColors.textTertiary,
                          ),
                        ),
                        child: _sansDocument
                            ? const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conducteur sans documents',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _sansDocument
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Sélectionnez si le conducteur ne présente aucun document.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 50.ms),

              const SizedBox(height: 20),

              // ── Conducteur ───────────────────────────────────────────────
              _sectionHeader('Conducteur', Icons.person_outline_rounded,
                  AppColors.primary),
              const SizedBox(height: 10),
              PremiumCard(
                child: Column(
                  children: [
                    _field(
                      ctrl: _nameCtrl,
                      label: 'Nom et prénom',
                      hint: 'Ex : IKONDO ELENGA Paul',
                      icon: Icons.person_rounded,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _licCtrl,
                      label: 'N° Permis',
                      hint: 'Ex : 51.074/PN/23',
                      icon: Icons.badge_outlined,
                      required: _hasPermis,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _dobCtrl,
                      label: 'Date de naissance',
                      hint: 'JJ-Mois-AAAA',
                      icon: Icons.cake_outlined,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _addressCtrl,
                      label: 'Adresse',
                      hint: 'Rue / quartier / ville',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _phoneCtrl,
                      label: 'Téléphone',
                      hint: '+242 06 000 0000',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Véhicule ─────────────────────────────────────────────────
              _sectionHeader('Véhicule', Icons.directions_car_outlined,
                  AppColors.warning),
              const SizedBox(height: 10),
              PremiumCard(
                child: Column(
                  children: [
                    _field(
                      ctrl: _plateCtrl,
                      label: 'Plaque d\'immatriculation',
                      hint: 'Ex : BZV-1234-A',
                      icon: Icons.confirmation_number_outlined,
                      caps: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSearching ? null : _searchByPlate,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary))
                            : const Icon(Icons.search_rounded,
                                size: 16, color: AppColors.primary),
                        label: Text(
                          _isSearching
                              ? 'Recherche en cours...'
                              : 'Rechercher conducteur en base',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            ctrl: _brandCtrl,
                            label: 'Marque',
                            hint: 'Toyota',
                            icon: Icons.directions_car_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            ctrl: _modelCtrl,
                            label: 'Modèle',
                            hint: 'Hilux',
                            icon: Icons.car_crash_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      ctrl: _colorCtrl,
                      label: 'Couleur',
                      hint: 'Ex : Blanc',
                      icon: Icons.color_lens_outlined,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // ── Documents présents ────────────────────────────────────────
              _sectionHeader('Documents présentés', Icons.folder_outlined,
                  AppColors.gold),
              const SizedBox(height: 10),
              PremiumCard(
                child: Column(
                  children: [
                    _docToggle(
                      label: 'Permis de conduire',
                      icon: Icons.credit_card_rounded,
                      value: _hasPermis,
                      onChanged: _sansDocument
                          ? null
                          : (v) => setState(() => _hasPermis = v),
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    _docToggle(
                      label: 'Carte grise',
                      icon: Icons.article_outlined,
                      value: _hasCarteGrise,
                      onChanged: _sansDocument
                          ? null
                          : (v) => setState(() => _hasCarteGrise = v),
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    _docToggle(
                      label: 'Certificat d\'assurance',
                      icon: Icons.shield_outlined,
                      value: _hasAssurance,
                      onChanged: _sansDocument
                          ? null
                          : (v) => setState(() => _hasAssurance = v),
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    _docToggle(
                      label: 'Contrôle technique',
                      icon: Icons.build_outlined,
                      value: _hasControle,
                      onChanged: _sansDocument
                          ? null
                          : (v) => setState(() => _hasControle = v),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              // Alerte documents manquants
              if (!_hasPermis || !_hasCarteGrise || !_hasAssurance ||
                  !_hasControle) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Des infractions documentaires seront automatiquement suggérées lors de la sélection.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ],

              const SizedBox(height: 28),

              PremiumButton(
                label: _isConfirming
                    ? 'Enregistrement...'
                    : 'Confirmer et continuer',
                icon: Icons.arrow_forward_rounded,
                isLoading: _isConfirming,
                onPressed: _isConfirming ? null : _confirm,
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.words,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          textCapitalization: caps,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon,
                size: 16, color: AppColors.textTertiary),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null
              : null,
        ),
      ],
    );
  }

  Widget _docToggle({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: value ? AppColors.success : AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: value ? AppColors.textPrimary : AppColors.error,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeThumbColor: AppColors.success,
            inactiveThumbColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}
