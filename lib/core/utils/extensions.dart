import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension BuildContextExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600 && MediaQuery.sizeOf(this).width < 1024;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1024;
}

extension StringExt on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');
  bool get isValidPhone => RegExp(r'^\+?[\d\s\-]{8,15}$').hasMatch(this);
}

extension DateTimeExt on DateTime {
  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedDateTime {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year '
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return formattedDate;
  }

  bool get isExpired => isBefore(DateTime.now());
  bool get isExpiringSoon =>
      isAfter(DateTime.now()) && isBefore(DateTime.now().add(const Duration(days: 30)));
}

extension IntExt on int {
  String get formattedAmount {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M FCFA';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(0)}K FCFA';
    return '$this FCFA';
  }

  String get withThousandSeparator {
    final str = toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

extension DoubleExt on double {
  String get formattedPercent => '${(this * 100).toStringAsFixed(1)}%';
}
