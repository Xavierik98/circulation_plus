import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/premium_button.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  /// Adresse email affichée (passée via query param ou prise depuis authState).
  final String? email;

  /// En mode dev/stub, l'URL de vérification directe est retournée par l'API.
  final String? devVerificationUrl;

  const VerifyEmailScreen({super.key, this.email, this.devVerificationUrl});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking  = false;
  bool _isResending = false;
  String? _devUrl;

  @override
  void initState() {
    super.initState();
    // Priorité : paramètre direct → sinon valeur stockée dans l'AuthState
    // (le redirect GoRouter fait perdre l'extra, donc on le récupère du provider)
    _devUrl = widget.devVerificationUrl?.isNotEmpty == true
        ? widget.devVerificationUrl
        : null;
    // On lira aussi depuis authProvider dans build() si _devUrl est encore null
  }

  String get _email =>
      widget.email ?? ref.read(authProvider).email ?? '';

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    final verified = await ref.read(authProvider.notifier).checkEmailVerified();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (verified) {
      // Le router redirect va détecter emailVerified=true et rediriger vers /citizen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email pas encore vérifié. Vérifiez votre boîte mail.'),
        backgroundColor: AppColors.warning,
      ));
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final url = await ref.read(authProvider.notifier).resendVerification(_email);
    if (!mounted) return;
    setState(() {
      _isResending = false;
      if (url != null && url.isNotEmpty) _devUrl = url;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Email renvoyé — vérifiez votre boîte mail.'),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer l'URL depuis l'AuthState si elle n'a pas été passée en paramètre
    final authUrl = ref.watch(authProvider).verificationUrl;
    if (_devUrl == null && authUrl != null && authUrl.isNotEmpty) {
      _devUrl = authUrl;
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Icône email animée
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.congoGreen, Color(0xFF059669)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.congoGreen.withValues(alpha: 0.35),
                          blurRadius: 24, offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mark_email_unread_rounded,
                        color: Colors.white, size: 38),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .scale(begin: const Offset(0.7, 0.7), delay: 100.ms,
                          duration: 400.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(duration: 1200.ms, delay: 600.ms),

                  const SizedBox(height: 28),

                  Text('Vérifiez votre email',
                      style: AppTextStyles.displaySmall,
                      textAlign: TextAlign.center)
                      .animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 10),

                  Text(
                    'Un lien d\'activation a été envoyé à :',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 260.ms),

                  const SizedBox(height: 6),

                  Text(
                    _email,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.congoGreen, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 28),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Step(n: '1', text: 'Ouvrez votre application email'),
                        SizedBox(height: 10),
                        _Step(n: '2', text: 'Cherchez un email de Circulation+'),
                        SizedBox(height: 10),
                        _Step(n: '3', text: 'Cliquez sur « Vérifier mon adresse email »'),
                        SizedBox(height: 10),
                        _Step(n: '4', text: 'Revenez ici et appuyez sur « J\'ai vérifié »'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 360.ms),

                  // Mode développement : afficher le lien directement
                  if (_devUrl != null && _devUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.developer_mode_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text('Mode développement — pas de SMTP configuré',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.warning)),
                          ]),
                          const SizedBox(height: 6),
                          Text('Lien de vérification direct :',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _devUrl!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lien copié')),
                              );
                            },
                            child: Text(
                              _devUrl!,
                              style: AppTextStyles.mono.copyWith(
                                  fontSize: 10,
                                  color: AppColors.info,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('(appuyez pour copier)',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary, fontSize: 10)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],

                  const SizedBox(height: 32),

                  // Bouton principal
                  PremiumButton(
                    label: _isChecking ? 'Vérification...' : 'J\'ai vérifié mon email ✓',
                    isLoading: _isChecking,
                    gradient: const LinearGradient(
                      colors: [AppColors.congoGreen, Color(0xFF059669)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: _isChecking ? null : _checkVerification,
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.3),

                  const SizedBox(height: 16),

                  // Renvoyer
                  TextButton.icon(
                    onPressed: _isResending ? null : _resend,
                    icon: _isResending
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      _isResending ? 'Envoi...' : 'Renvoyer l\'email',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.congoGreen),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 12),

                  // Retour connexion
                  TextButton(
                    onPressed: () => context.go('/role'),
                    child: Text(
                      'Retour à la connexion',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ).animate().fadeIn(delay: 530.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: AppColors.congoGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(n,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.congoGreen, fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
