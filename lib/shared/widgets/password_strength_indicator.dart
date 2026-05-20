import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum PasswordStrength { empty, weak, medium, strong, veryStrong }

class PasswordPolicy {
  final bool minLength;      // >= 10
  final bool hasUppercase;   // A-Z
  final bool hasLowercase;   // a-z
  final bool hasDigit;       // 0-9
  final bool hasSpecial;     // !@#$%...
  final bool maxLength;      // <= 64

  const PasswordPolicy({
    this.minLength = false,
    this.hasUppercase = false,
    this.hasLowercase = false,
    this.hasDigit = false,
    this.hasSpecial = false,
    this.maxLength = true,
  });

  static PasswordPolicy check(String password) {
    return PasswordPolicy(
      minLength:    password.length >= 10,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasDigit:     password.contains(RegExp(r'[0-9]')),
      hasSpecial:   password.contains(RegExp('[!@#\$%^&*()\\-_=+\\[\\]{};:\'",.<>/?\\\\|`~]')),
      maxLength:    password.length <= 64,
    );
  }

  int get score {
    if (!minLength) return 0;
    int s = 0;
    if (hasUppercase) s++;
    if (hasLowercase) s++;
    if (hasDigit) s++;
    if (hasSpecial) s++;
    return s;
  }

  PasswordStrength get strength {
    if (!minLength) return PasswordStrength.weak;
    return switch (score) {
      1      => PasswordStrength.weak,
      2      => PasswordStrength.medium,
      3      => PasswordStrength.strong,
      >= 4   => PasswordStrength.veryStrong,
      _      => PasswordStrength.weak,
    };
  }

  bool get isValid => minLength && hasUppercase && hasLowercase && hasDigit && hasSpecial && maxLength;

  String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    final p = PasswordPolicy.check(value);
    if (!p.maxLength)    return 'Maximum 64 caractères';
    if (!p.minLength)    return 'Minimum 10 caractères requis';
    if (!p.hasUppercase) return 'Ajoutez au moins une majuscule (A-Z)';
    if (!p.hasLowercase) return 'Ajoutez au moins une minuscule (a-z)';
    if (!p.hasDigit)     return 'Ajoutez au moins un chiffre (0-9)';
    if (!p.hasSpecial)   return 'Ajoutez au moins un caractère spécial (!@#\$%...)';
    return null;
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final policy = PasswordPolicy.check(password);
    final strength = policy.strength;

    final (label, color, filledBars) = switch (strength) {
      PasswordStrength.weak      => ('Faible',        AppColors.error,   1),
      PasswordStrength.medium    => ('Moyen',          AppColors.warning, 2),
      PasswordStrength.strong    => ('Fort',           AppColors.info,    3),
      PasswordStrength.veryStrong=> ('Très fort ✓',   AppColors.success, 4),
      _                          => ('Faible',         AppColors.error,   0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Barres de force
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < filledBars ? color : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Force : $label',
              style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            Text(
              'ISO 27001/27005',
              style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Checklist des critères
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _Criterion('10+ caractères', policy.minLength),
            _Criterion('Majuscule',      policy.hasUppercase),
            _Criterion('Minuscule',      policy.hasLowercase),
            _Criterion('Chiffre',        policy.hasDigit),
            _Criterion('Spécial !@#\$',  policy.hasSpecial),
          ],
        ),
      ],
    );
  }
}

class _Criterion extends StatelessWidget {
  final String label;
  final bool met;
  const _Criterion(this.label, this.met);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 12,
          color: met ? AppColors.success : AppColors.textDisabled,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: met ? AppColors.success : AppColors.textDisabled,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
