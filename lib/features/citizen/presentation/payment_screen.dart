import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/premium_button.dart';

class PaymentScreen extends StatefulWidget {
  final String fineId;
  const PaymentScreen({super.key, required this.fineId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  String _selectedMethod = 'mtn';
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  late AnimationController _successController;
  final _phoneController = TextEditingController(text: '+242 06 789 0123');

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _successController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 2500));
    setState(() {
      _isProcessing = false;
      _paymentSuccess = true;
    });
    _successController.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.pushReplacement('/citizen/receipt/${widget.fineId}');
  }

  @override
  Widget build(BuildContext context) {
    final fine = FineModel.mockFines.firstWhere(
      (f) => f.id == widget.fineId,
      orElse: () => FineModel.mockFines.first,
    );

    if (_paymentSuccess) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paiement sécurisé', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, fontWeight: FontWeight.w600)),
            Text('PORTAIL CITOYEN', style: TextStyle(color: Color(0xFF009A44), fontSize: 9, letterSpacing: 1.5)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Amount summary
            _buildAmountCard(fine),

            const SizedBox(height: 24),

            Text('Méthode de paiement', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),

            // MTN Mobile Money
            _PaymentMethodCard(
              id: 'mtn',
              name: 'MTN Mobile Money',
              logo: 'MTN',
              logoColor: const Color(0xFFFFCC00),
              logoBg: const Color(0xFF1A1500),
              subtitle: 'Disponible 24h/24',
              isSelected: _selectedMethod == 'mtn',
              onSelect: () => setState(() => _selectedMethod = 'mtn'),
            ),
            const SizedBox(height: 10),

            // Airtel Money
            _PaymentMethodCard(
              id: 'airtel',
              name: 'Airtel Money',
              logo: 'AIRTEL',
              logoColor: const Color(0xFFFF0000),
              logoBg: const Color(0xFF1A0000),
              subtitle: 'Disponible 24h/24',
              isSelected: _selectedMethod == 'airtel',
              onSelect: () => setState(() => _selectedMethod = 'airtel'),
            ),

            const SizedBox(height: 24),

            // Phone number
            Text('Numéro de téléphone', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                hintText: '+242 06 000 0000',
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 8),
            Text(
              'Vous recevrez une notification USSD sur ce numéro.',
              style: AppTextStyles.bodySmall,
            ),

            const SizedBox(height: 24),

            // Security note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé par DGST · Chiffrement TLS 1.3 · Aucun frais supplémentaire',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 28),

            PremiumButton(
              label: _isProcessing ? 'Traitement en cours...' : 'Confirmer le paiement',
              isLoading: _isProcessing,
              icon: Icons.payment_rounded,
              onPressed: _isProcessing ? null : _processPayment,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amende à régler', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                Text(fine.infractionLabel, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(fine.reference, style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: AppTextStyles.caption),
              Text(
                '${(fine.amount / 1000).toStringAsFixed(0)} 000',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
              ),
              Text('FCFA', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _successController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120 + _successController.value * 30,
                        height: 120 + _successController.value * 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.05 * (1 - _successController.value)),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.successGradient,
                          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 30)],
                        ),
                        child: Transform.scale(
                          scale: _successController.value,
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Text('Paiement réussi!', style: AppTextStyles.headlineMedium).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
              Text(
                'Votre amende a été réglée.\nRedirection vers le reçu...',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String id;
  final String name;
  final String logo;
  final Color logoColor;
  final Color logoBg;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PaymentMethodCard({
    required this.id,
    required this.name,
    required this.logo,
    required this.logoColor,
    required this.logoBg,
    required this.subtitle,
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
          color: isSelected ? AppColors.congoGreen.withValues(alpha: 0.07) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.congoGreen : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: logoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: logoColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  logo,
                  style: TextStyle(
                    color: logoColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.titleSmall),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.congoGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.congoGreen : AppColors.textTertiary,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}
