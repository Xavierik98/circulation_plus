import 'package:flutter/services.dart';

/// Validation et formatage des numéros de téléphone congolais (+242).
///
/// Format attendu : indicatif optionnel (+242 ou 242) suivi de 9 chiffres
/// commençant par 0 (ex. 06 123 4567, 05 987 6543, +242 04 555 1212).
class CongoPhone {
  CongoPhone._();

  /// Numéro local à 9 chiffres commençant par 0, indicatif +242/242 optionnel.
  static final RegExp _pattern = RegExp(r'^(?:\+?242)?0\d{8}$');

  /// Retire tout sauf chiffres et le signe + initial.
  static String _clean(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'[\s.-]'), '');
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// `true` si [value] correspond à un numéro congolais valide.
  static bool isValid(String value) => _pattern.hasMatch(_clean(value));

  /// Validateur pour [TextFormField]. [required] = false autorise un champ vide.
  static String? Function(String?) validator({bool required = true}) {
    return (value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) {
        return required ? 'Le numéro de téléphone est requis' : null;
      }
      if (!isValid(v)) {
        return 'Numéro congolais invalide (ex. 06 123 4567)';
      }
      return null;
    };
  }

  /// Limite la saisie aux chiffres, à un éventuel "+" en tête, et à 13
  /// caractères max (+242 + 9 chiffres).
  static List<TextInputFormatter> get inputFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[\d+\s]')),
        LengthLimitingTextInputFormatter(17),
      ];
}
