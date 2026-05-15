import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

enum UserRole { police, citizen, admin, none }

class AuthState {
  final UserRole role;
  final String? userId;
  final String? userName;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.role = UserRole.none,
    this.userId,
    this.userName,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => role != UserRole.none;

  AuthState copyWith({
    UserRole? role,
    String? userId,
    String? userName,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      role: role ?? this.role,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(AppConstants.prefUserRole);
    final userId = prefs.getString(AppConstants.prefUserId);
    if (roleStr != null) {
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.none,
      );
      if (role != UserRole.none) {
        state = AuthState(role: role, userId: userId);
      }
    }
  }

  Future<bool> login({
    required UserRole role,
    required String identifier,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock validation
    if (otp != '1234') {
      state = state.copyWith(isLoading: false, error: 'Code OTP invalide');
      return false;
    }

    final userId = switch (role) {
      UserRole.police => 'OFF001',
      UserRole.citizen => 'CIT001',
      UserRole.admin => 'ADM001',
      UserRole.none => '',
    };

    final userName = switch (role) {
      UserRole.police => 'J.P. Moukala',
      UserRole.citizen => 'Thierry Nguesso',
      UserRole.admin => 'Admin DGST',
      UserRole.none => '',
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserRole, role.name);
    await prefs.setString(AppConstants.prefUserId, userId);

    state = AuthState(role: role, userId: userId, userName: userName);
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefUserId);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
