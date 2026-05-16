class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Circulation+';
  static const String appVersion = '1.0.0';
  static const String appBuild = '2024.1';
  static const String ministry = 'Ministère de l\'Intérieur';
  static const String dgst = 'DGST — Direction Générale des Services Techniques';
  static const String country = 'République du Congo';

  // Backend API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Shared Preferences Keys
  static const String prefLocale = 'locale';
  static const String prefUserRole = 'user_role';
  static const String prefUserId = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefUserBadge = 'user_badge';
  static const String prefDarkMode = 'dark_mode';
  static const String prefOnboarded = 'onboarded';

  // Secure storage keys (tokens)
  static const String secureAccessToken = 'access_token';
  static const String secureRefreshToken = 'refresh_token';

  // Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 28.0;
  static const double radiusFull = 100.0;

  // Currency
  static const String currency = 'FCFA';
  static const String currencySymbol = 'F';

  // Fine amounts (FCFA)
  static const Map<String, int> fineAmounts = {
    'speeding_mild': 15000,
    'speeding_moderate': 30000,
    'speeding_severe': 60000,
    'no_helmet': 5000,
    'red_light': 20000,
    'no_seatbelt': 10000,
    'no_license': 25000,
    'no_registration': 15000,
    'phone_driving': 20000,
    'illegal_parking': 5000,
    'no_insurance': 30000,
    'vehicle_overload': 40000,
  };

  // Congo cities
  static const List<String> congoCities = [
    'Brazzaville',
    'Pointe-Noire',
    'Dolisie',
    'Nkayi',
    'Impfondo',
    'Ouesso',
    'Madingou',
    'Kinkala',
    'Sibiti',
    'Mossendjo',
  ];

  // License categories
  static const List<String> licenseCategories = ['A', 'B', 'C', 'D', 'E'];

  // Max license points
  static const int maxLicensePoints = 12;
}
