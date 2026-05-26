import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../data/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _loading  = false;
  bool _sent     = false;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final identifier = _usePhone
        ? _phoneCtrl.text.trim()
        : _emailCtrl.text.trim().toLowerCase();
    try {
      await ApiClient.instance.post(
        '/api/auth/forgot-password',
        body: {'identifier': identifier},
      );
    } catch (_) {
      // Anti-enumeration : afficher succès même en erreur réseau
    } finally {
      if (mounted) setState(() { _sent = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor      = isDark ? AppColors.background      : const Color(0xFFF4F6FA);
    final surfColor    = isDark ? AppColors.surface         : Colors.white;
    final surfVarColor = isDark ? AppColors.surfaceVariant  : const Color(0xFFF1F5F9);
    final borderColor  = isDark ? AppColors.cardBorder      : const Color(0xFFE2E8F0);
    final textPriColor = isDark ? AppColors.textPrimary     : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: textPriColor),
          onPressed: () => context.pop(),
        ),
        title: Text('Mot de passe oublié', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? _buildSuccess()
              : _buildForm(bgColor, surfVarColor, borderColor, textPriColor),
        ),
      ),
    );
  }

  Widget _buildForm(Color bgColor, Color surfVar, Color border, Color textPri) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 38, color: AppColors.primary),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 28),
          Text('Réinitialiser votre mot de passe', style: AppTextStyles.titleLarge)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            _usePhone
                ? 'Saisissez votre numéro de téléphone. Un lien sera envoyé à votre email associé.'
                : 'Saisissez l\'email associé à votre compte. Vous recevrez un lien valable 1 heure.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 24),

          // Toggle email / téléphone
          Container(
            decoration: BoxDecoration(
              color: surfVar,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              _ModeTab(label: 'Email',      icon: Icons.email_outlined,  selected: !_usePhone, onTap: () => setState(() => _usePhone = false)),
              _ModeTab(label: 'Téléphone', icon: Icons.phone_outlined,  selected: _usePhone,  onTap: () => setState(() => _usePhone = true)),
            ]),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _usePhone
                ? TextFormField(
                    key: const ValueKey('phone'),
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium.copyWith(color: textPri),
                    validator: (v) => (v == null || v.trim().length < 8) ? 'Numéro invalide' : null,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '+242 06 000 0000',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.textTertiary),
                    ),
                  )
                : TextFormField(
                    key: const ValueKey('email'),
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium.copyWith(color: textPri),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Adresse email',
                      hintText: 'votre@email.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textTertiary),
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          PremiumButton(
            label: 'Envoyer le lien',
            isLoading: _loading,
            icon: Icons.send_rounded,
            onPressed: _loading ? null : _submit,
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Retour à la connexion',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final identifier = _usePhone ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 30)],
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 48),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7)),
        const SizedBox(height: 28),
        Text('Lien envoyé !',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.success))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Si un compte est associé à\n$identifier\nun lien de réinitialisation a été envoyé par email.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text('Ce lien expire dans 1 heure.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning))
            .animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Retour à la connexion',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: selected ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
