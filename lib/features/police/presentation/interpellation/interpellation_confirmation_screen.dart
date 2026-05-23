import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/models/interpellation_state.dart';
import '../../../../shared/models/fine_model.dart';
import '../../../../shared/services/pdf_service.dart';
import '../../../../data/providers.dart';
import '../../../../data/repositories.dart';
import '../../../../data/api_client.dart';
import '../../../auth/providers/auth_provider.dart';

class InterpellationConfirmationScreen extends ConsumerStatefulWidget {
  const InterpellationConfirmationScreen({super.key});

  @override
  ConsumerState<InterpellationConfirmationScreen> createState() =>
      _InterpellationConfirmationScreenState();
}

class _InterpellationConfirmationScreenState
    extends ConsumerState<InterpellationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;

  // ── Soumission PV ─────────────────────────────────────────────────────────
  bool _isSubmitting = true;
  bool _submitError = false;
  String? _submitErrorMsg;
  List<FineModel> _createdFines = [];

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    // Soumettre le PV dès l'arrivée sur cet écran
    WidgetsBinding.instance.addPostFrameCallback((_) => _submitPv());
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _submitPv() async {
    final interp = ref.read(interpellationProvider);
    setState(() {
      _isSubmitting = true;
      _submitError = false;
      _submitErrorMsg = null;
    });

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final bodies = interp.selectedInfractions.map((infraction) {
        return <String, dynamic>{
          'infractionTypeId': infraction.id,
          'driverPhone': interp.driverPhone.isNotEmpty
              ? interp.driverPhone
              : '+242000000000', // fallback si non renseigné
          if (interp.driverName.isNotEmpty) 'driverName': interp.driverName,
          if (interp.vehiclePlate.isNotEmpty) 'vehiclePlate': interp.vehiclePlate,
          if (interp.driverLicense.isNotEmpty) 'numeroPermis': interp.driverLicense,
          if (interp.lieuPrecis.isNotEmpty) 'adresseApprox': interp.lieuPrecis,
          if (interp.gpsLat != null) 'latitude': interp.gpsLat,
          if (interp.gpsLng != null) 'longitude': interp.gpsLng,
          'refusSignature': interp.signatureRefused,
          'verbaliseLe': now,
        };
      }).toList();

      if (bodies.isEmpty) {
        // Pas d'infractions sélectionnées — improbable mais on gère
        setState(() => _isSubmitting = false);
        return;
      }

      final fines = await FineRepository().createBatch(bodies);
      if (mounted) {
        setState(() {
          _createdFines = fines;
          _isSubmitting = false;
        });
        _checkController.forward();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = true;
          _submitErrorMsg = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = true;
          _submitErrorMsg = 'Erreur réseau. Vérifiez votre connexion.';
        });
      }
    }
  }

  bool _isPdfLoading = false;

  Future<void> _printPdf(InterpellationState interp, String reference) async {
    final auth = ref.read(authProvider);
    setState(() => _isPdfLoading = true);
    try {
      await PvPdfService.printPv(
        interp: interp,
        reference: reference,
        agentName: auth.userName ?? 'Agent PNC',
        agentBadge: auth.badgeNumber ?? '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interp = ref.watch(interpellationProvider);
    final total = interp.totalAmount;
    final formattedTotal = _fmt(total);
    final isRefusal = interp.signatureRefused;

    // ── Loading / Error ──────────────────────────────────────────────────────
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text('Enregistrement du PV…',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ),
      );
    }

    if (_submitError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 56, color: AppColors.error),
                const SizedBox(height: 20),
                Text('Échec de l\'enregistrement',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _submitErrorMsg ?? 'Une erreur est survenue.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                PremiumButton(
                  label: 'Réessayer',
                  icon: Icons.refresh_rounded,
                  onPressed: _submitPv,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/police'),
                  child: const Text('Abandonner',
                      style: TextStyle(color: AppColors.textTertiary)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Référence du 1er PV créé (ou fallback local)
    final mainRef = _createdFines.isNotEmpty
        ? _createdFines.first.reference
        : 'PV-${DateTime.now().year}-${_refSuffix()}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Success animation ──────────────────────────────────
              _buildSuccessAnimation(),

              const SizedBox(height: 28),

              Text(
                isRefusal
                    ? 'Refus enregistré\nConvocation émise'
                    : 'Interpellation\nenregistrée',
                style: AppTextStyles.displaySmall.copyWith(height: 1.2),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: 10),

              Text(
                isRefusal
                    ? 'Les documents saisis sont consignés dans le PV.\nUne convocation a été générée sous 7 jours.'
                    : 'L\'amende a été émise et le conducteur\na été notifié.',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 28),

              // ── Reference card ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _ConfirmRow(label: 'Référence', value: mainRef),
                    const Divider(height: 20, color: AppColors.divider),
                    _ConfirmRow(
                      label: 'Conducteur',
                      value: interp.driverName.isNotEmpty
                          ? interp.driverName
                          : '—',
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    _ConfirmRow(
                      label: 'Véhicule',
                      value: interp.vehiclePlate.isNotEmpty
                          ? '${interp.vehicleBrand} — ${interp.vehiclePlate}'
                          : '—',
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    _ConfirmRow(
                      label: 'PV créé(s)',
                      value:
                          '${_createdFines.isNotEmpty ? _createdFines.length : interp.selectedInfractions.length} PV',
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    _ConfirmRow(
                      label: 'Montant total',
                      value: '$formattedTotal FCFA',
                      valueColor: AppColors.primary,
                    ),
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

              const SizedBox(height: 16),

              // ── Notification / Documents saisis ──────────────────
              if (isRefusal && interp.documentsSeizes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_open_outlined,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            '${interp.documentsSeizes.length} document(s) saisi(s)',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...interp.documentsSeizes.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('• ${d.label}',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                          )),
                    ],
                  ),
                ).animate().fadeIn(delay: 1100.ms)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SMS + notification envoyés au conducteur',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1100.ms),

              const SizedBox(height: 28),

              // ── Actions ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: _isPdfLoading ? 'PDF...' : 'Imprimer PDF',
                      icon: _isPdfLoading
                          ? Icons.hourglass_bottom_rounded
                          : Icons.picture_as_pdf_outlined,
                      onPressed: _isPdfLoading
                          ? null
                          : () => _printPdf(
                                interp,
                                _createdFines.isNotEmpty
                                    ? _createdFines.first.reference
                                    : 'PV-${DateTime.now().year}-${_refSuffix()}',
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PremiumButton(
                      label: 'Nouvelle interpellation',
                      icon: Icons.add_rounded,
                      onPressed: () {
                        ref.read(interpellationProvider.notifier).reset();
                        ref.read(selectedInfractionsProvider.notifier).state = [];
                        context.go('/police');
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1200.ms),

              const SizedBox(height: 12),

              // ── Retour tableau de bord ────────────────────────────
              TextButton.icon(
                onPressed: () {
                  ref.read(interpellationProvider.notifier).reset();
                  ref.read(selectedInfractionsProvider.notifier).state = [];
                  context.go('/police');
                },
                icon: const Icon(Icons.dashboard_outlined, size: 16),
                label: const Text('Retour au tableau de bord'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                ),
              ).animate().fadeIn(delay: 1300.ms),

              const SizedBox(height: 16),
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
                color: AppColors.success
                    .withValues(alpha: 0.05 * (1 - _checkController.value)),
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 1.5),
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
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  /// Génère un suffixe de référence à partir du timestamp courant.
  String _refSuffix() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000000;
    return ms.toString().padLeft(6, '0');
  }

  /// Formatte un montant XAF : 25000 → "25 000"
  String _fmt(int amount) {
    if (amount < 1000) return amount.toString();
    final thousands = amount ~/ 1000;
    final remainder = amount % 1000;
    if (remainder == 0) return '$thousands 000';
    return '$thousands ${remainder.toString().padLeft(3, '0')}';
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
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
