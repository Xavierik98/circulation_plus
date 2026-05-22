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
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post(
        '/api/auth/forgot-password',
        body: {'email': _emailCtrl.text.trim().toLowerCase()},
      );
      setState(() => _sent = true);
    } catch (_) {
      // Anti-enumeration : même en cas d'erreur réseau on affiche "envoyé"
      setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Mot de passe oublié', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration:
                const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Icône
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  size: 38, color: AppColors.primary),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 28),
          Text('Réinitialiser votre mot de passe',
                  style: AppTextStyles.titleLarge)
              .animate()
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'Saisissez l\'adresse email associée à votre compte. '
            'Vous recevrez un lien valable 1 heure pour choisir un nouveau mot de passe.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: const Icon(Icons.email_outlined,
                  size: 20, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
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
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final email = _emailCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 30),
            ],
          ),
          child:
              const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 48),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7)),
        const SizedBox(height: 28),
        Text('Email envoyé !',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.success))
            .animate()
            .fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Si un compte est associé à\n$email\nun lien de réinitialisation a été envoyé.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text(
          'Ce lien expire dans 1 heure.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Retour à la connexion',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
