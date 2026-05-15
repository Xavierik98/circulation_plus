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

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  late UserRole _userRole;
  late String _roleTitle;
  late IconData _roleIcon;
  late Gradient _roleGradient;

  @override
  void initState() {
    super.initState();
    _userRole = switch (widget.role) {
      'police' => UserRole.police,
      'citizen' => UserRole.citizen,
      'admin' => UserRole.admin,
      _ => UserRole.citizen,
    };
    _roleTitle = switch (_userRole) {
      UserRole.police => 'Agent de Police',
      UserRole.citizen => 'Citoyen',
      UserRole.admin => 'Administrateur',
      UserRole.none => '',
    };
    _roleIcon = switch (_userRole) {
      UserRole.police => Icons.local_police_rounded,
      UserRole.citizen => Icons.person_rounded,
      UserRole.admin => Icons.admin_panel_settings_rounded,
      UserRole.none => Icons.person_rounded,
    };
    _roleGradient = switch (_userRole) {
      UserRole.police => AppColors.primaryGradient,
      UserRole.citizen => const LinearGradient(
          colors: [AppColors.success, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      UserRole.admin => const LinearGradient(
          colors: [AppColors.info, Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      UserRole.none => AppColors.primaryGradient,
    };
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_identifierController.text.isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
    _showSnack('Code OTP envoyé au +242 06 *** **23', isSuccess: true);
  }

  Future<void> _login() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).login(
          role: _userRole,
          identifier: _identifierController.text,
          otp: _otpController.text,
        );
    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showSnack(ref.read(authProvider).error ?? 'Erreur de connexion');
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _LoginBgPainter(_userRole))),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back button
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

                  const SizedBox(height: 40),

                  // Role badge
                  if (_userRole == UserRole.police)
                    const PncBadge(size: 68, showGlow: true)
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .scale(begin: const Offset(0.6, 0.6), delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack)
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: _roleGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(_roleIcon, color: Colors.white, size: 30),
                    ).animate().fadeIn(delay: 100.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        delay: 100.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  Text(
                    'Connexion',
                    style: AppTextStyles.displaySmall,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),

                  Text(
                    'Portail $_roleTitle',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  // Identifier field
                  _buildLabel(_userRole == UserRole.police ? 'Matricule Agent' : 'Numéro National / Téléphone'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: _userRole == UserRole.police
                        ? TextInputType.text
                        : TextInputType.phone,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: _userRole == UserRole.police ? 'Ex: PNB-4521' : '+242 06 000 0000',
                      prefixIcon: Icon(
                        _userRole == UserRole.police
                            ? Icons.badge_rounded
                            : Icons.phone_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ).animate().fadeIn(delay: 400.ms),

                  if (_otpSent) ...[
                    const SizedBox(height: 20),
                    _buildLabel('Code OTP'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.titleMedium.copyWith(
                        letterSpacing: 8,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        hintStyle: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textDisabled,
                          letterSpacing: 6,
                        ),
                        counterText: '',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        suffixText: 'Renvoyer',
                        suffixStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

                    const SizedBox(height: 8),
                    Text(
                      'Conseil : utilisez "1234" pour ce démo',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  const SizedBox(height: 32),

                  // CTA Button
                  PremiumButton(
                    label: _otpSent ? 'Se connecter' : 'Envoyer le code OTP',
                    isLoading: _isLoading,
                    gradient: _roleGradient,
                    icon: _otpSent ? Icons.login_rounded : Icons.send_rounded,
                    onPressed: _isLoading ? null : (_otpSent ? _login : _sendOtp),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

                  const SizedBox(height: 16),

                  // Demo hint
                  if (!_otpSent)
                    Center(
                      child: Text(
                        'Entrez n\'importe quel identifiant pour démarrer',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),

                  // Security badge
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Connexion sécurisée — DGST Congo',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  final UserRole role;
  _LoginBgPainter(this.role);

  @override
  void paint(Canvas canvas, Size size) {
    final glowColor = role == UserRole.police
        ? AppColors.gold.withValues(alpha: 0.08)
        : role == UserRole.citizen
            ? AppColors.congoGreen.withValues(alpha: 0.06)
            : AppColors.info.withValues(alpha: 0.06);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor, Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.12),
        radius: size.width * 0.75,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), size.width * 0.75, paint);

    // Bottom-left glow
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.primary.withValues(alpha: 0.04), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.85),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85), size.width * 0.5, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
