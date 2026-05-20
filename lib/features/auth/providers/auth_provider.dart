import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/api_client.dart';
import '../../../data/repositories.dart';

// ── Comptes de démonstration (actifs quand le backend est injoignable) ────────
// Même identifiants que le seed Prisma : email / PIN 0000
const _demoUsers = {
  'admin@pnc.cg':    {'id': 'demo-admin',   'role': 'ADMIN',   'name': 'Administrateur PNC',  'badgeNumber': null},
  'agent1@pnc.cg':   {'id': 'demo-agent1',  'role': 'POLICE',  'name': 'Jean Mbemba',          'badgeNumber': 'PNC-2024-001'},
  'agent2@pnc.cg':   {'id': 'demo-agent2',  'role': 'POLICE',  'name': 'Aline Okemba',         'badgeNumber': 'PNC-2024-002'},
  'agent3@pnc.cg':   {'id': 'demo-agent3',  'role': 'POLICE',  'name': 'Patrick Loubota',      'badgeNumber': 'PNC-2024-003'},
  'citoyen1@pnc.cg': {'id': 'demo-cit1',   'role': 'CITOYEN', 'name': 'Marie Samba',          'badgeNumber': null},
  'citoyen2@pnc.cg': {'id': 'demo-cit2',   'role': 'CITOYEN', 'name': 'Thomas Ngolo',         'badgeNumber': null},
};

enum UserRole { police, citizen, admin, none }

UserRole _roleFromBackend(String? upper) {
  switch (upper) {
    case 'POLICE':
      return UserRole.police;
    case 'CITOYEN':
      return UserRole.citizen;
    case 'ADMIN':
      return UserRole.admin;
    default:
      return UserRole.none;
  }
}

class AuthState {
  final UserRole role;
  final String? userId;
  final String? userName;
  final String? badgeNumber;
  final String? telephone;
  final String? email;
  final bool mustChangePassword;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.role = UserRole.none,
    this.userId,
    this.userName,
    this.badgeNumber,
    this.telephone,
    this.email,
    this.mustChangePassword = false,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => role != UserRole.none;

  /// Initiales à partir du nom complet (ex: "Marie Samba" → "MS")
  String get initials {
    if (userName == null || userName!.trim().isEmpty) return '?';
    final parts = userName!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  AuthState copyWith({
    UserRole? role,
    String? userId,
    String? userName,
    String? badgeNumber,
    String? telephone,
    String? email,
    bool? mustChangePassword,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      role: role ?? this.role,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      badgeNumber: badgeNumber ?? this.badgeNumber,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    if (!await _repo.hasSession()) return;
    try {
      final user = await _repo.me();
      await _persist(user);
      state = AuthState(
        role: _roleFromBackend(user['role'] as String?),
        userId: user['id'] as String?,
        userName: user['name'] as String?,
        badgeNumber: user['badgeNumber'] as String?,
        telephone: user['telephone'] as String?,
        email: user['email'] as String?,
        mustChangePassword: user['mustChangePassword'] as bool? ?? false,
      );
    } catch (_) {
      // Session invalide : on reste déconnecté.
      await _repo.logout();
    }
  }

  Future<void> _persist(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final role = _roleFromBackend(user['role'] as String?);
    await prefs.setString(AppConstants.prefUserRole, role.name);
    await prefs.setString(AppConstants.prefUserId, user['id'] as String? ?? '');
    await prefs.setString(AppConstants.prefUserName, user['name'] as String? ?? '');
    await prefs.setString(AppConstants.prefUserBadge, user['badgeNumber'] as String? ?? '');
    await prefs.setString(AppConstants.prefUserPhone, user['telephone'] as String? ?? '');
    await prefs.setString(AppConstants.prefUserEmail, user['email'] as String? ?? '');
  }

  Future<bool> login({
    required UserRole role,
    required String email,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // ── Tentative de connexion sur le backend ────────────────────────────
      final user = await _repo.login(email, pin, role.name);
      await _persist(user);
      state = AuthState(
        role: _roleFromBackend(user['role'] as String?),
        userId: user['id'] as String?,
        userName: user['name'] as String?,
        badgeNumber: user['badgeNumber'] as String?,
        telephone: user['telephone'] as String?,
        email: user['email'] as String?,
        mustChangePassword: user['mustChangePassword'] as bool? ?? false,
      );
      return true;
    } on ApiException catch (e) {
      // Erreur réseau (backend injoignable) → mode démo offline
      if (e.code == 'NETWORK_ERROR') {
        return _loginDemo(email, pin);
      }
      // Erreur métier (mauvais identifiants, etc.) → on affiche le message
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      // Autre erreur inattendue → tenter le mode démo
      return _loginDemo(email, pin);
    }
  }

  /// Mode démo offline : comptes prédéfinis, PIN universel 0000.
  /// Activé automatiquement quand le backend est injoignable.
  bool _loginDemo(String email, String pin) {
    if (pin != 'Demo@1234!') {
      state = state.copyWith(
        isLoading: false,
        error: 'Backend injoignable — Mode démo : utilisez le mot de passe "Demo@1234!"',
      );
      return false;
    }
    final demoUser = _demoUsers[email.toLowerCase().trim()];
    if (demoUser == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Backend injoignable — Mode démo\n'
            'Comptes : agent1@pnc.cg · citoyen1@pnc.cg · admin@pnc.cg\n'
            'Mot de passe : Demo@1234!',
      );
      return false;
    }
    state = AuthState(
      role: _roleFromBackend(demoUser['role']),
      userId: demoUser['id'],
      userName: demoUser['name'],
      badgeNumber: demoUser['badgeNumber'],
      error: '⚡ Mode démo — backend non connecté',
    );
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String telephone,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.register(name, email, telephone, pin);
      await _persist(user);
      state = AuthState(
        role: _roleFromBackend(user['role'] as String?),
        userId: user['id'] as String?,
        userName: user['name'] as String?,
        badgeNumber: user['badgeNumber'] as String?,
        telephone: user['telephone'] as String?,
        email: user['email'] as String?,
        mustChangePassword: user['mustChangePassword'] as bool? ?? false,
      );
      return true;
    } on ApiException catch (e) {
      if (e.code == 'NETWORK_ERROR') {
        state = state.copyWith(
          isLoading: false,
          error: 'Backend injoignable — impossible de créer un compte en mode démo.',
        );
        return false;
      }
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création du compte.',
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.changePassword(currentPassword, newPassword);
      await _persist(user);
      state = state.copyWith(
        isLoading: false,
        mustChangePassword: false,
        userName: user['name'] as String?,
        error: null,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du changement de mot de passe.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserName);
    await prefs.remove(AppConstants.prefUserBadge);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(AuthRepository()),
);
