import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/api_client.dart';
import '../../../data/repositories.dart';

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
  final bool isLoading;
  final String? error;

  const AuthState({
    this.role = UserRole.none,
    this.userId,
    this.userName,
    this.badgeNumber,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => role != UserRole.none;

  AuthState copyWith({
    UserRole? role,
    String? userId,
    String? userName,
    String? badgeNumber,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      role: role ?? this.role,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      badgeNumber: badgeNumber ?? this.badgeNumber,
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
    await prefs.setString(
        AppConstants.prefUserName, user['name'] as String? ?? '');
    await prefs.setString(
        AppConstants.prefUserBadge, user['badgeNumber'] as String? ?? '');
  }

  Future<bool> login({
    required UserRole role,
    required String email,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email, pin, role.name);
      await _persist(user);
      state = AuthState(
        role: _roleFromBackend(user['role'] as String?),
        userId: user['id'] as String?,
        userName: user['name'] as String?,
        badgeNumber: user['badgeNumber'] as String?,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connexion impossible. Vérifiez votre réseau.',
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
