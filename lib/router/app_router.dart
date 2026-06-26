import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/role_selection_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/police/presentation/police_shell.dart';
import '../features/police/presentation/police_dashboard.dart';
import '../features/police/presentation/driver_history_screen.dart';
import '../features/police/presentation/police_notifications_screen.dart';
import '../features/police/presentation/police_id_card_screen.dart';
import '../features/police/presentation/interpellation/scan_screen.dart';
import '../features/police/presentation/interpellation/ocr_preview_screen.dart';
import '../features/police/presentation/interpellation/interpellation_location_screen.dart';
import '../features/police/presentation/interpellation/infraction_selection_screen.dart';
import '../features/police/presentation/interpellation/fine_calculation_screen.dart';
import '../features/police/presentation/interpellation/signature_screen.dart';
import '../features/police/presentation/interpellation/signature_refusal_screen.dart';
import '../features/police/presentation/interpellation/interpellation_confirmation_screen.dart';
import '../features/citizen/presentation/citizen_shell.dart';
import '../features/citizen/presentation/citizen_dashboard.dart';
import '../features/citizen/presentation/fine_details_screen.dart';
import '../features/citizen/presentation/payment_screen.dart';
import '../features/citizen/presentation/license_status_screen.dart';
import '../features/citizen/presentation/receipt_screen.dart';
import '../features/citizen/presentation/citizen_notifications_screen.dart';
import '../features/citizen/presentation/citizen_profile_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/admin_dashboard.dart';
import '../features/admin/presentation/map_screen.dart';
import '../features/admin/presentation/officers_management_screen.dart';
import '../features/admin/presentation/revenue_dashboard.dart';
import '../features/admin/presentation/register_agent_screen.dart';
import '../features/admin/presentation/fines_management_screen.dart';
import '../features/admin/presentation/security_screen.dart';
import '../features/admin/presentation/users_management_screen.dart';
import '../features/police/presentation/license_verify_screen.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _policeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'police');
final _citizenNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'citizen');
final _adminNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

final routerProvider = Provider<GoRouter>((ref) {
  // ⚠️  Ne PAS utiliser ref.watch ici — cela recrée le GoRouter à chaque
  // changement d'état et provoque un retour à l'écran d'accueil (/splash).
  // On utilise ref.listen + router.refresh() à la place.
  late final GoRouter router;

  router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // ref.read : lit l'état courant sans s'y abonner (le refresh s'en charge)
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isAuth = authState.isAuthenticated;
      final isPublicRoute = location.startsWith('/splash') ||
          location.startsWith('/role') ||
          location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/forgot-password') ||
          location.startsWith('/verify-email');
      final isChangePassword = location.startsWith('/change-password');

      if (!isAuth && !isPublicRoute && !isChangePassword) return '/role';

      // Changement de mot de passe obligatoire : bloquer tout accès au dashboard.
      if (isAuth && authState.mustChangePassword && !isChangePassword) {
        return '/change-password?mandatory=true';
      }

      // Email non vérifié (CITOYEN connecté mais pas encore validé) :
      // bloquer l'accès au dashboard.
      if (isAuth &&
          authState.role == UserRole.citizen &&
          !authState.emailVerified &&
          !location.startsWith('/verify-email') &&
          !isChangePassword) {
        return '/verify-email';
      }

      if (isAuth && isPublicRoute && !location.startsWith('/splash')) {
        // Ne pas rediriger depuis /verify-email si l'email n'est pas encore vérifié
        // (sinon : boucle /citizen ↔ /verify-email)
        if (location.startsWith('/verify-email') &&
            authState.role == UserRole.citizen &&
            !authState.emailVerified) {
          return null;
        }
        return switch (authState.role) {
          UserRole.police => '/police',
          UserRole.citizen => '/citizen',
          UserRole.admin => '/admin',
          UserRole.none => '/role',
        };
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login/:role',
        builder: (context, state) => LoginScreen(role: state.pathParameters['role']!),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => ChangePasswordScreen(
          mandatory: state.uri.queryParameters['mandatory'] == 'true',
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerifyEmailScreen(
            email: extra?['email'] as String? ?? state.uri.queryParameters['email'],
            devVerificationUrl: extra?['devUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Police Shell
      ShellRoute(
        navigatorKey: _policeNavigatorKey,
        builder: (context, state, child) => PoliceShell(child: child),
        routes: [
          GoRoute(path: '/police', builder: (_, __) => const PoliceDashboard()),
          GoRoute(path: '/police/history', builder: (_, __) => const DriverHistoryScreen()),
          GoRoute(
            path: '/police/notifications',
            builder: (_, __) => const PoliceNotificationsScreen(),
          ),
        ],
      ),

      // Interpellation Flow (full-screen, outside shell)
      // Étape 1 : Scan
      GoRoute(path: '/police/scan', builder: (_, __) => const ScanScreen()),
      // Étape 2 : Aperçu OCR / Saisie conducteur-véhicule
      GoRoute(path: '/police/ocr', builder: (_, __) => const OcrPreviewScreen()),
      // Étape 3 : Lieu de l'infraction + département (NOUVEAU)
      GoRoute(path: '/police/location', builder: (_, __) => const InterpellationLocationScreen()),
      // Étape 4 : Sélection des infractions
      GoRoute(
        path: '/police/infractions',
        builder: (_, __) => const InfractionSelectionScreen(),
      ),
      // Étape 5 : Calcul de l'amende
      GoRoute(
        path: '/police/fine-calc',
        builder: (_, __) => const FineCalculationScreen(),
      ),
      // Étape 6 : Signature
      GoRoute(path: '/police/signature', builder: (_, __) => const SignatureScreen()),
      // Étape 6b : Refus de signature → saisie documents
      GoRoute(path: '/police/refusal', builder: (_, __) => const SignatureRefusalScreen()),
      // Confirmation finale
      GoRoute(
        path: '/police/confirmation',
        builder: (_, __) => const InterpellationConfirmationScreen(),
      ),
      GoRoute(
        path: '/police/id-card',
        builder: (_, __) => const PoliceIdCardScreen(),
      ),
      GoRoute(
        path: '/police/license-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LicenseVerifyScreen(
            initialLicense: extra?['license'] as String?,
            initialPlate: extra?['plate'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/police/settings',
        builder: (_, __) => const SettingsScreen(),
      ),

      // Citizen Shell
      ShellRoute(
        navigatorKey: _citizenNavigatorKey,
        builder: (context, state, child) => CitizenShell(child: child),
        routes: [
          GoRoute(path: '/citizen', builder: (_, __) => const CitizenDashboard()),
          GoRoute(
            path: '/citizen/notifications',
            builder: (_, __) => const CitizenNotificationsScreen(),
          ),
          GoRoute(path: '/citizen/license', builder: (_, __) => const LicenseStatusScreen()),
        ],
      ),
      GoRoute(
        path: '/citizen/profile',
        builder: (_, __) => const CitizenProfileScreen(),
      ),
      GoRoute(
        path: '/citizen/fine/:id',
        builder: (context, state) => FineDetailsScreen(fineId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/citizen/payment/:id',
        builder: (context, state) => PaymentScreen(fineId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/citizen/receipt/:id',
        builder: (context, state) => ReceiptScreen(fineId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/citizen/settings',
        builder: (_, __) => const SettingsScreen(),
      ),

      // Admin Shell
      ShellRoute(
        navigatorKey: _adminNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
          GoRoute(path: '/admin/map', builder: (_, __) => const MapScreen()),
          GoRoute(
            path: '/admin/officers',
            builder: (_, __) => const OfficersManagementScreen(),
          ),
          GoRoute(path: '/admin/revenue', builder: (_, __) => const RevenueDashboard()),
        ],
      ),
      GoRoute(
        path: '/admin/fines',
        builder: (_, __) => const FinesManagementScreen(),
      ),
      GoRoute(
        path: '/admin/add-agent',
        builder: (_, __) => const RegisterAgentScreen(),
      ),
      GoRoute(
        path: '/admin/security',
        builder: (_, __) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const UsersManagementScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );

  // Quand l'état d'auth change, on rafraîchit le router existant
  // (re-exécute les redirections) sans le recréer.
  ref.listen<AuthState>(authProvider, (_, __) => router.refresh());

  return router;
});
