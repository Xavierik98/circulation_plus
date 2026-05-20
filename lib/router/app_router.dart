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
import '../features/police/presentation/interpellation/scan_screen.dart';
import '../features/police/presentation/interpellation/ocr_preview_screen.dart';
import '../features/police/presentation/interpellation/infraction_selection_screen.dart';
import '../features/police/presentation/interpellation/fine_calculation_screen.dart';
import '../features/police/presentation/interpellation/signature_screen.dart';
import '../features/police/presentation/interpellation/interpellation_confirmation_screen.dart';
import '../features/citizen/presentation/citizen_shell.dart';
import '../features/citizen/presentation/citizen_dashboard.dart';
import '../features/citizen/presentation/fine_details_screen.dart';
import '../features/citizen/presentation/payment_screen.dart';
import '../features/citizen/presentation/license_status_screen.dart';
import '../features/citizen/presentation/receipt_screen.dart';
import '../features/citizen/presentation/citizen_notifications_screen.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/admin/presentation/admin_dashboard.dart';
import '../features/admin/presentation/map_screen.dart';
import '../features/admin/presentation/officers_management_screen.dart';
import '../features/admin/presentation/revenue_dashboard.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _policeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'police');
final _citizenNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'citizen');
final _adminNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuth = authState.isAuthenticated;
      final isPublicRoute = location.startsWith('/splash') ||
          location.startsWith('/role') ||
          location.startsWith('/login') ||
          location.startsWith('/register');
      final isChangePassword = location.startsWith('/change-password');

      if (!isAuth && !isPublicRoute && !isChangePassword) return '/role';

      // Changement de mot de passe obligatoire : bloquer tout accès au dashboard.
      if (isAuth && authState.mustChangePassword && !isChangePassword) {
        return '/change-password?mandatory=true';
      }

      if (isAuth && isPublicRoute && !location.startsWith('/splash')) {
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
      GoRoute(path: '/police/scan', builder: (_, __) => const ScanScreen()),
      GoRoute(path: '/police/ocr', builder: (_, __) => const OcrPreviewScreen()),
      GoRoute(
        path: '/police/infractions',
        builder: (_, __) => const InfractionSelectionScreen(),
      ),
      GoRoute(
        path: '/police/fine-calc',
        builder: (_, __) => const FineCalculationScreen(),
      ),
      GoRoute(path: '/police/signature', builder: (_, __) => const SignatureScreen()),
      GoRoute(
        path: '/police/confirmation',
        builder: (_, __) => const InterpellationConfirmationScreen(),
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
        path: '/admin/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});
