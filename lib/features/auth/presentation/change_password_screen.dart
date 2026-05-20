import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final bool mandatory; // true = premier login, false = changement volontaire
  const ChangePasswordScreen({super.key, this.mandatory = false});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _currentCtrl      = TextEditingController();
  final _newCtrl          = TextEditingController();
  final _confirmCtrl      = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _isLoading   = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).changePassword(
      currentPassword: _currentCtrl.text,
      newPassword:     _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe mis à jour avec succès'),
        backgroundColor: AppColors.success,
      ));
      // Redirige vers le bon dashboard selon le rôle
      final role = ref.read(authProvider).role;
      context.go(switch (role) {
        UserRole.police  => '/police',
        UserRole.citizen => '/citizen',
        UserRole.admin   => '/admin',
        UserRole.none    => '/role',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(authProvider).error ?? 'Erreur lors du changement'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Barre Congo
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Bouton retour (seulement si pas obligatoire)
                    if (!widget.mandatory)
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppColors.textPrimary),
                        ),
                      ).animate().fadeIn()
                    else
                      const SizedBox(height: 42),

                    const SizedBox(height: 32),

                    // Icône
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20, offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
                    ).animate().fadeIn(delay: 100.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 24),

                    Text(
                      widget.mandatory
                          ? 'Changement de mot de passe obligatoire'
                          : 'Changer mon mot de passe',
                      style: AppTextStyles.displaySmall,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                    const SizedBox(height: 8),

                    if (widget.mandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Votre compte nécessite un changement de mot de passe '
                              'avant de continuer.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                            ),
                          ),
                        ]),
                      ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 32),

                    // Mot de passe actuel
                    _label('Mot de passe actuel'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentCtrl,
                      obscureText: !_showCurrent,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Mot de passe actuel',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primary, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showCurrent = !_showCurrent),
                          child: Icon(
                            _showCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textTertiary, size: 20,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Mot de passe actuel requis' : null,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 20),

                    // Nouveau mot de passe
                    _label('Nouveau mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newCtrl,
                      obscureText: !_showNew,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Min. 10 car. — Maj, chiffre, spécial',
                        prefixIcon: const Icon(Icons.lock_rounded,
                            color: AppColors.primary, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showNew = !_showNew),
                          child: Icon(
                            _showNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textTertiary, size: 20,
                          ),
                        ),
                      ),
                      validator: const PasswordPolicy().validate,
                    ).animate().fadeIn(delay: 350.ms),

                    PasswordStrengthIndicator(password: _newCtrl.text)
                        .animate().fadeIn(delay: 360.ms),

                    const SizedBox(height: 20),

                    // Confirmer
                    _label('Confirmer le nouveau mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showNew,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Répétez le nouveau mot de passe',
                        prefixIcon: Icon(Icons.lock_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v != _newCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    PremiumButton(
                      label: _isLoading ? 'Mise à jour...' : 'Mettre à jour',
                      isLoading: _isLoading,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1E3A8A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      icon: Icons.check_circle_rounded,
                      onPressed: _isLoading ? null : _submit,
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.3),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
  );
}
