import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
  final String? photoUrl;
  final bool mustChangePassword;
  final bool emailVerified;
  final bool isLoading;
  final String? error;
  /// URL de vérification email retournée par le backend en mode dev/stub.
  /// Stockée ici pour survivre au redirect GoRouter.
  final String? verificationUrl;

  const AuthState({
    this.role = UserRole.none,
    this.userId,
    this.userName,
    this.badgeNumber,
    this.telephone,
    this.email,
    this.photoUrl,
    this.mustChangePassword = false,
    this.emailVerified = true,
    this.isLoading = false,
    this.error,
    this.verificationUrl,
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
    String? photoUrl,
    bool? mustChangePassword,
    bool? emailVerified,
    bool? isLoading,
    String? error,
    String? verificationUrl,
  }) {
    return AuthState(
      role: role ?? this.role,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      badgeNumber: badgeNumber ?? this.badgeNumber,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      emailVerified: emailVerified ?? this.emailVerified,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationUrl: verificationUrl ?? this.verificationUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _restore();
  }

  final AuthRepository _repo;

  // ── Session timeout (30 min d'inactivité) ────────────────────────────────
  static const _sessionTimeout = Duration(minutes: 30);
  Timer? _sessionTimer;

  /// Réinitialise le minuteur d'inactivité. À appeler à chaque interaction.
  void resetSessionTimer() {
    _sessionTimer?.cancel();
    if (state.isAuthenticated) {
      _sessionTimer = Timer(_sessionTimeout, () {
        debugPrint('[Session] Timeout 30 min — déconnexion automatique');
        logout();
      });
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  /// Récupère le token FCM et l'envoie au backend.
  /// Non-bloquant : toute erreur (Firebase non configuré, réseau) est ignorée.
  Future<void> _pushFcmToken() async {
    try {
      // Demander la permission sur iOS (ignoré sur Android < 13).
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _repo.updateFcmToken(token);
        debugPrint('[FCM] Token enregistré : ${token.substring(0, 10)}…');
      }

      // Écouter les renouvellements automatiques de token.
      messaging.onTokenRefresh.listen((newToken) {
        _repo.updateFcmToken(newToken).catchError((_) {});
      });
    } catch (e) {
      // Firebase non configuré (placeholder) ou autre erreur — non bloquant.
      debugPrint('[FCM] Impossible d\'enregistrer le token : $e');
    }
  }

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
        photoUrl: user['photoUrl'] as String?,
        mustChangePassword: user['mustChangePassword'] as bool? ?? false,
        emailVerified: user['emailVerified'] as bool? ?? true,
      );
      // Enregistrer le token FCM pour les notifications push.
      _pushFcmToken();
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

  /// Tente de recuperer les coordonnees GPS actuelles.
  /// Non-bloquant : retourne null si permission refusee, GPS indisponible ou timeout.
  Future<({double lat, double lng})?> _getPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      // GPS non disponible, permission manquante, ou timeout — connexion continue.
      return null;
    }
  }

  Future<bool> login({
    required UserRole role,
    required String email,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // ── Coordonnees GPS (best-effort, non bloquant) ──────────────────────
      final position = await _getPosition();

      // ── Tentative de connexion sur le backend ────────────────────────────
      final user = await _repo.login(
        email,
        pin,
        role.name,
        lat: position?.lat,
        lng: position?.lng,
      );
      await _persist(user);
      state = AuthState(
        role: _roleFromBackend(user['role'] as String?),
        userId: user['id'] as String?,
        userName: user['name'] as String?,
        badgeNumber: user['badgeNumber'] as String?,
        telephone: user['telephone'] as String?,
        email: user['email'] as String?,
        photoUrl: user['photoUrl'] as String?,
        mustChangePassword: user['mustChangePassword'] as bool? ?? false,
        emailVerified: user['emailVerified'] as bool? ?? true,
      );
      // Enregistrer le token FCM pour les notifications push.
      _pushFcmToken();
      // Démarrer le timer de session (30 min d'inactivité → déconnexion).
      resetSessionTimer();
      // Passer automatiquement "En service" pour les agents police.
      if (_roleFromBackend(user['role'] as String?) == UserRole.police) {
        _setOnDutyAuto(position?.lat, position?.lng);
      }
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
    if (pin != 'Admin@1234!') {
      state = state.copyWith(
        isLoading: false,
        error: 'Backend injoignable — Mode démo : utilisez le mot de passe "Admin@1234!"',
      );
      return false;
    }
    final demoUser = _demoUsers[email.toLowerCase().trim()];
    if (demoUser == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Backend injoignable — Mode démo\n'
            'Comptes : agent1@pnc.cg · citoyen1@pnc.cg · admin@pnc.cg\n'
            'Mot de passe : Admin@1234!',
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

  /// Inscription citoyen. Retourne `null` si échec, sinon la `verificationUrl`
  /// (non-null en mode dev/stub, null si SMTP configuré).
  Future<String?> register({
    required String name,
    required String email,
    String? telephone,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.register(name, email, telephone, pin);
      final user = data['user'] as Map<String, dynamic>;
      final verificationUrl = data['verificationUrl'] as String?;

      // Authentifier l'utilisateur
      await _persist(user);
      final devUrl = verificationUrl ?? '';
      final isVerified = user['emailVerified'] as bool? ?? false;
      state = AuthState(
        role: _roleFromBackend(user['role'] as String?),
        userId: user['id'] as String?,
        userName: user['name'] as String?,
        badgeNumber: user['badgeNumber'] as String?,
        telephone: user['telephone'] as String?,
        email: user['email'] as String?,
        mustChangePassword: user['mustChangePassword'] as bool? ?? false,
        emailVerified: isVerified, // Vrai en dev (auto-vérifié), false en prod
        verificationUrl: devUrl.isNotEmpty ? devUrl : null,
      );
      // Enregistrer le token FCM pour les notifications push.
      _pushFcmToken();
      return devUrl; // '' = auto-vérifié (dev) ou SMTP ok, non-vide = lien direct stub
    } on ApiException catch (e) {
      // ignore: avoid_print
      print('[REGISTER ERROR] code=${e.code} status=${e.statusCode} msg=${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e, st) {
      // ignore: avoid_print
      print('[REGISTER CATCH] $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Vérifier si l'email a été confirmé (appel /me après clic sur le lien).
  Future<bool> checkEmailVerified() async {
    try {
      final user = await _repo.me();
      if (user['emailVerified'] as bool? ?? false) {
        await _persist(user);
        state = AuthState(
          role: _roleFromBackend(user['role'] as String?),
          userId: user['id'] as String?,
          userName: user['name'] as String?,
          badgeNumber: user['badgeNumber'] as String?,
          telephone: user['telephone'] as String?,
          email: user['email'] as String?,
          photoUrl: user['photoUrl'] as String?,
          mustChangePassword: user['mustChangePassword'] as bool? ?? false,
          emailVerified: true,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Renvoyer l'email de vérification.
  Future<String?> resendVerification(String email) async {
    try {
      final data = await _repo.resendVerification(email);
      return data['verificationUrl'] as String?;
    } catch (_) {
      return null;
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

  /// Upload photo de profil (base64). Met à jour photoUrl dans l'état local.
  Future<bool> uploadPhoto(String imageBase64, String mimeType) async {
    try {
      final data = await _repo.uploadPhoto(imageBase64, mimeType);
      final url = data['photoUrl'] as String?;
      if (url != null) {
        state = state.copyWith(photoUrl: url);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Passe automatiquement un agent en "En service" juste après sa connexion.
  /// Non-bloquant : toute erreur réseau est ignorée.
  void _setOnDutyAuto(double? lat, double? lng) {
    ApiClient.instance.post(
      '/api/officers/me/status',
      body: {
        'onDuty': true,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    ).catchError((_) {});
  }

  /// Enregistre le token FCM reçu de firebase_messaging.
  /// À appeler après que le plugin firebase_messaging fournit le token.
  /// Ex: FirebaseMessaging.instance.getToken().then((t) => auth.notifier.registerFcmToken(t))
  Future<void> registerFcmToken(String? token) async {
    try {
      await _repo.updateFcmToken(token);
    } catch (_) {
      // Non bloquant : la notification push fonctionnera
      // quand le token sera enregistré à la prochaine session.
    }
  }

  Future<void> logout() async {
    _sessionTimer?.cancel();
    // Révoquer le token FCM avant la déconnexion (bonnes pratiques)
    try { await _repo.updateFcmToken(null); } catch (_) {}
    // Passer hors service si policier
    try {
      await ApiClient.instance.post('/api/officers/me/status', body: {'onDuty': false});
    } catch (_) {}
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
