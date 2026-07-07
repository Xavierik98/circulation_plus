import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/pnc_badge.dart';
import '../providers/auth_provider.dart';

/// Étape 2 de connexion — code à 6 chiffres obligatoire pour POLICE/ADMIN,
/// envoyé par email (+ SMS si numéro renseigné).
class TwoFactorScreen extends ConsumerStatefulWidget {
  final String challengeToken;
  final String channel; // 'email' | 'email+sms'
  final String roleTitle;

  const TwoFactorScreen({
    super.key,
    required this.challengeToken,
    required this.channel,
    required this.roleTitle,
  });

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showSnack('Saisissez les 6 chiffres du code');
      return;
    }
    setState(() => _isLoading = true);
    final success = await ref
        .read(authProvider.notifier)
        .verify2fa(widget.challengeToken, code);
    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showSnack(ref.read(authProvider).error ?? 'Code invalide');
    }
    // Succès : le redirect global de GoRouter (basé sur authProvider.role)
    // bascule automatiquement vers le bon dashboard.
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final ok = await ref
        .read(authProvider.notifier)
        .resend2fa(widget.challengeToken);
    setState(() => _isResending = false);
    if (!mounted) return;
    _showSnack(
      ok ? 'Nouveau code envoyé' : 'Échec de l\'envoi, réessayez',
      isSuccess: ok,
    );
    if (ok) _startCooldown();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  String get _channelLabel => widget.channel == 'email+sms'
      ? 'votre email et votre numéro de téléphone'
      : 'votre email';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 32),

              const PncBadge(size: 64, showGlow: true)
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .scale(begin: const Offset(0.6, 0.6), delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text('Vérification en deux étapes', style: AppTextStyles.displaySmall)
                  .animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

              const SizedBox(height: 8),

              Text(
                'Un code à 6 chiffres a été envoyé à $_channelLabel '
                'pour confirmer la connexion ${widget.roleTitle}.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 36),

              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 10,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                ),
                onFieldSubmitted: (_) => _verify(),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

              const SizedBox(height: 8),

              Text(
                'Le code est valable 5 minutes.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),

              const SizedBox(height: 32),

              PremiumButton(
                label: 'Vérifier',
                isLoading: _isLoading,
                gradient: AppColors.primaryGradient,
                icon: Icons.verified_user_rounded,
                onPressed: _isLoading ? null : _verify,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 ? null : _resend,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Renvoyer le code (${_resendCooldown}s)'
                              : 'Renvoyer le code',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                        ),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
