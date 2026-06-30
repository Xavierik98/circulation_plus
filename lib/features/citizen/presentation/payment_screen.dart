import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/date_input_field.dart';
import '../../../data/repositories.dart';
import '../../../data/api_client.dart';
import '../../../data/providers.dart';
import '../../../core/utils/congo_phone.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Provider local pour la méthode sélectionnée ─────────────────────────────
final _selectedMethodProvider = StateProvider<String>((ref) => 'mtn');

class PaymentScreen extends ConsumerStatefulWidget {
  final String fineId;
  const PaymentScreen({super.key, required this.fineId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String? _successPaymentId;
  late AnimationController _successController;

  // Mobile Money
  final _phoneController = TextEditingController();

  // Trésor public
  final _quittanceController = TextEditingController();
  DateTime? _quittanceDate;
  final _agentTresorController = TextEditingController();

  final _paymentRepo = PaymentRepository();

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    // Pré-remplir le téléphone avec celui du compte citoyen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = ref.read(authProvider).telephone ?? '';
      if (phone.isNotEmpty && _phoneController.text.isEmpty) {
        _phoneController.text = phone;
      }
    });
  }

  @override
  void dispose() {
    _successController.dispose();
    _phoneController.dispose();
    _quittanceController.dispose();
    _agentTresorController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final method = ref.read(_selectedMethodProvider);

    if (method == 'tresor') {
      if (_quittanceController.text.trim().isEmpty) {
        _snack('Veuillez saisir le numéro de quittance');
        return;
      }
    } else {
      final phoneError = CongoPhone.validator()(_phoneController.text);
      if (phoneError != null) {
        _snack(phoneError);
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      if (method == 'tresor') {
        await _processTresor();
      } else {
        await _processMomo(method.toUpperCase()); // 'MTN' | 'AIRTEL'
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Erreur réseau. Vérifiez votre connexion.');
    } finally {
      if (mounted && !_paymentSuccess) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processMomo(String operateur) async {
    final result = await _paymentRepo.initiateMomo(
      fineId: widget.fineId,
      operateur: operateur,
      telephone: _phoneController.text.trim(),
    );

    final paymentUrl = result['paymentUrl'] as String?;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      _snack('Impossible d\'obtenir l\'URL de paiement');
      return;
    }

    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Impossible d\'ouvrir la page de paiement');
      return;
    }

    // En mode stub : l'URL `/__stub_pay/...` est servie localement.
    // En prod : CinetPay redirige vers l'app après paiement.
    // On affiche un dialogue pour confirmer le retour après paiement.
    if (mounted) {
      setState(() => _isProcessing = false);
      _showReturnDialog();
    }
  }

  Future<void> _processTresor() async {
    final isoDate = _quittanceDate != null
        ? '${_quittanceDate!.year}-'
            '${_quittanceDate!.month.toString().padLeft(2, '0')}-'
            '${_quittanceDate!.day.toString().padLeft(2, '0')}'
        : null;

    final result = await _paymentRepo.recordTresor(
      fineId: widget.fineId,
      quittanceNumero: _quittanceController.text.trim(),
      quittanceDate: isoDate,
      agentTresor: _agentTresorController.text.trim(),
    );

    _successPaymentId = result['paymentId'] as String?;
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _paymentSuccess = true;
      });
      _successController.forward();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _successPaymentId != null) {
        context.pushReplacement('/citizen/receipt/$_successPaymentId');
      } else if (mounted) {
        context.pop();
      }
    }
  }

  void _showReturnDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: StitchColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Paiement Mobile Money', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
        content: Text(
          'Validez le paiement USSD sur votre téléphone, puis revenez ici.',
          style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Retour au dashboard (le statut sera mis à jour par webhook)
              context.go('/citizen');
            },
            child: const Text('J\'ai payé',
                style: TextStyle(color: StitchColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Annuler',
                style: TextStyle(color: StitchColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: StitchColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final asyncFine = ref.watch(fineDetailProvider(widget.fineId));
    final method = ref.watch(_selectedMethodProvider);

    if (_paymentSuccess) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: StitchColors.background,
      appBar: AppBar(
        backgroundColor: StitchColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: StitchColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paiement sécurisé', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
            Text(
              'PORTAIL CITOYEN',
              style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant).copyWith(
                  color: StitchColors.primary, fontSize: 9, letterSpacing: 1.5),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
              height: 3,
              decoration:
                  const BoxDecoration(gradient: StitchColors.congoFlagGradient)),
        ),
      ),
      body: asyncFine.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: StitchColors.primary)),
        error: (e, _) => Center(
          child: Text('Impossible de charger l\'amende : $e',
              style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
              textAlign: TextAlign.center),
        ),
        data: (fine) => _buildPaymentBody(context, fine, method),
      ),
    );
  }

  Widget _buildPaymentBody(
      BuildContext context, FineModel fine, String method) {
    final userName = ref.read(authProvider).userName ?? '';
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Récapitulatif amende ─────────────────────────────
            _buildAmountCard(fine).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ── Titre méthode ────────────────────────────────────
            Text('Méthode de paiement', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Choisissez comment régler votre amende.',
              style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                  .copyWith(color: StitchColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            // ── MTN Mobile Money ─────────────────────────────────
            _PaymentMethodCard(
              id: 'mtn',
              name: 'MTN Mobile Money',
              logoText: 'MTN',
              logoColor: const Color(0xFFFFCC00),
              logoBg: const Color(0xFF1A1500),
              subtitle: 'Paiement instantané via USSD',
              icon: Icons.smartphone_rounded,
              isSelected: method == 'mtn',
              onSelect: () =>
                  ref.read(_selectedMethodProvider.notifier).state = 'mtn',
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 10),

            // ── Airtel Money ─────────────────────────────────────
            _PaymentMethodCard(
              id: 'airtel',
              name: 'Airtel Money',
              logoText: 'AIRTEL',
              logoColor: const Color(0xFFFF3B30),
              logoBg: const Color(0xFF1A0000),
              subtitle: 'Paiement instantané via USSD',
              icon: Icons.smartphone_rounded,
              isSelected: method == 'airtel',
              onSelect: () =>
                  ref.read(_selectedMethodProvider.notifier).state = 'airtel',
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 10),

            // ── Trésor public ─────────────────────────────────────
            _PaymentMethodCard(
              id: 'tresor',
              name: 'Trésor Public',
              logoText: 'TRÉSOR',
              logoColor: StitchColors.secondary,
              logoBg: const Color(0xFF1A1200),
              subtitle: 'Paiement en agence — quittance officielle',
              icon: Icons.account_balance_rounded,
              isSelected: method == 'tresor',
              onSelect: () =>
                  ref.read(_selectedMethodProvider.notifier).state = 'tresor',
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // ── Formulaire selon méthode ──────────────────────────
            if (method == 'mtn' || method == 'airtel')
              _buildMobileMoneyForm(method)
            else
              _buildTresorForm(userName),

            const SizedBox(height: 20),

            // ── Note sécurité ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: StitchColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: StitchColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 16, color: StitchColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      method == 'tresor'
                          ? 'La quittance du Trésor public vaut preuve de paiement. '
                              'Conservez l\'original pour la restitution de vos documents.'
                          : 'Vous serez redirigé vers la page de paiement Mobile Money. '
                              'Confirmez ensuite le paiement USSD sur votre téléphone.',
                      style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                          .copyWith(color: StitchColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(method == 'tresor' ? Icons.account_balance_rounded : Icons.open_in_new_rounded),
                label: Text(
                  _isProcessing
                      ? 'Traitement en cours...'
                      : method == 'tresor'
                          ? 'Enregistrer le paiement Trésor'
                          : 'Payer avec ${method.toUpperCase()}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: method == 'tresor' ? StitchColors.secondary : StitchColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
    );
  }

  // ─── Carte montant ──────────────────────────────────────────────────────────
  Widget _buildAmountCard(FineModel fine) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1D3A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StitchColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: StitchColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amende à régler',
                    style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                        .copyWith(color: StitchColors.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(fine.infractionLabel,
                    style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant)
                        .copyWith(color: StitchColors.onSurface)),
                const SizedBox(height: 2),
                Text(fine.reference,
                    style: GoogleFonts.courierPrime(fontSize: 13, color: StitchColors.onSurface)
                        .copyWith(fontSize: 11, color: StitchColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
              Text(
                _fmt(fine.amount),
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: StitchColors.onSurface)
                    .copyWith(color: StitchColors.primary),
              ),
              Text('FCFA',
                  style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                      .copyWith(color: StitchColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Formulaire Mobile Money ────────────────────────────────────────────────
  Widget _buildMobileMoneyForm(String method) {
    final color =
        method == 'mtn' ? const Color(0xFFFFCC00) : const Color(0xFFFF3B30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Numéro Mobile Money', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: CongoPhone.inputFormatters,
          style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant)
              .copyWith(color: StitchColors.onSurface),
          decoration: InputDecoration(
            prefixIcon:
                Icon(Icons.phone_rounded, color: color, size: 20),
            hintText: '+242 06 000 0000',
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          'Vous serez redirigé vers la page de paiement ${method.toUpperCase()}. '
          'Confirmez l\'USSD, puis revenez dans l\'application.',
          style:
              GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant).copyWith(color: StitchColors.onSurfaceVariant),
        ),
      ],
    );
  }

  // ─── Formulaire Trésor public ───────────────────────────────────────────────
  Widget _buildTresorForm(String citizenName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bannière info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StitchColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StitchColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: StitchColors.secondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rendez-vous dans une agence du Trésor public muni de votre '
                  'PV de contravention. Obtenez votre quittance officielle, '
                  'puis saisissez son numéro ci-dessous.',
                  style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                      .copyWith(color: StitchColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        // Numéro quittance
        Text('Numéro de quittance *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quittanceController,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.courierPrime(fontSize: 13, color: StitchColors.onSurface).copyWith(color: StitchColors.onSurface),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.receipt_long_outlined,
                color: StitchColors.secondary, size: 20),
            hintText: 'Ex : QTT-2026-00012345',
          ),
        ).animate().fadeIn(delay: 50.ms),

        const SizedBox(height: 14),

        // Date de paiement
        Text('Date du paiement', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        DateInputField(
          initialValue: _quittanceDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          label: 'Date du paiement',
          iconColor: StitchColors.secondary,
          helpText: 'Date du paiement',
          onChanged: (d) => setState(() => _quittanceDate = d),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 14),

        // Agent caisse
        Text('Nom de l\'agent à la caisse', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _agentTresorController,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant)
              .copyWith(color: StitchColors.onSurface),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_outline_rounded,
                color: StitchColors.secondary, size: 20),
            hintText: 'Nom de l\'agent à la caisse (optionnel)',
          ),
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 14),

        // Avertissement restitution documents
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StitchColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: StitchColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open_outlined,
                  color: StitchColors.secondary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'La restitution de vos documents saisis interviendra '
                  'après vérification du paiement par l\'administration PNC.',
                  style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                      .copyWith(color: StitchColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  // ─── Écran succès ────────────────────────────────────────────────────────────
  Widget _buildSuccessScreen() {
    final method = ref.read(_selectedMethodProvider);
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _successController,
                builder: (context, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120 + _successController.value * 30,
                      height: 120 + _successController.value * 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: StitchColors.primary.withValues(
                            alpha: 0.05 * (1 - _successController.value)),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [StitchColors.primary, StitchColors.primaryContainer]),
                        boxShadow: [
                          BoxShadow(
                              color: StitchColors.primary.withValues(alpha: 0.4),
                              blurRadius: 30)
                        ],
                      ),
                      child: Transform.scale(
                        scale: _successController.value,
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Paiement enregistré !',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: StitchColors.onSurface))
                  .animate()
                  .fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
              Text(
                method == 'tresor'
                    ? 'Votre paiement au Trésor public a été enregistré.\n'
                        'La restitution des documents interviendra sous 48h.'
                    : 'Paiement Mobile Money en cours de confirmation.\n'
                        'Vous recevrez une notification.',
                style: GoogleFonts.inter(fontSize: 16, color: StitchColors.onSurfaceVariant)
                    .copyWith(color: StitchColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(StitchColors.primary),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int amount) {
    if (amount < 1000) return amount.toString();
    final t = amount ~/ 1000;
    final r = amount % 1000;
    return r == 0 ? '$t 000' : '$t ${r.toString().padLeft(3, '0')}';
  }
}

// ─── Carte méthode de paiement ────────────────────────────────────────────────
class _PaymentMethodCard extends StatelessWidget {
  final String id;
  final String name;
  final String logoText;
  final Color logoColor;
  final Color logoBg;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PaymentMethodCard({
    required this.id,
    required this.name,
    required this.logoText,
    required this.logoColor,
    required this.logoBg,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? logoColor.withValues(alpha: 0.06)
              : StitchColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? logoColor : StitchColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: logoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: logoColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: id == 'tresor'
                    ? Icon(Icons.account_balance_rounded,
                        color: logoColor, size: 22)
                    : Text(
                        logoText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ).copyWith(color: logoColor),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)
                          .copyWith(color: StitchColors.onSurfaceVariant)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? logoColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? logoColor : StitchColors.onSurfaceVariant,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
