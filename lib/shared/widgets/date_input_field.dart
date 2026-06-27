import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Champ de saisie de date — toujours via [showDatePicker], jamais en texte libre.
/// Remplace les anciens `TextFormField` avec hint "JJ/MM/AAAA".
class DateInputField extends FormField<DateTime> {
  DateInputField({
    super.key,
    DateTime? initialValue,
    required DateTime firstDate,
    required DateTime lastDate,
    required String label,
    String hint = 'JJ/MM/AAAA',
    IconData icon = Icons.calendar_today_outlined,
    Color iconColor = AppColors.textTertiary,
    String helpText = 'Sélectionner une date',
    super.validator,
    super.enabled,
    ValueChanged<DateTime?>? onChanged,
  }) : super(
          initialValue: initialValue,
          builder: (state) {
            final value = state.value;
            return GestureDetector(
              onTap: !state.widget.enabled
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final initial = value ??
                          (lastDate.isBefore(now) ? lastDate : now)
                              .clamp(firstDate, lastDate);
                      final picked = await showDatePicker(
                        context: state.context,
                        initialDate: initial,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        helpText: helpText,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: AppColors.surface,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        state.didChange(picked);
                        onChanged?.call(picked);
                      }
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: Icon(icon, size: 20, color: iconColor),
                  suffixIcon: const Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.textTertiary),
                  labelStyle: AppTextStyles.bodySmall,
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  errorText: state.errorText,
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(
                  value != null ? formatDate(value) : '',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ),
            );
          },
        );

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

extension on DateTime {
  DateTime clamp(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}
