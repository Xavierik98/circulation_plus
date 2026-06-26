import '../shared/models/fine_model.dart';
import '../shared/models/officer_model.dart';
import '../shared/models/notification_model.dart';
import '../shared/models/infraction_model.dart';
import '../shared/models/user_model.dart';
import 'api_client.dart';
import 'mappers.dart';

/// Page paginée générique renvoyée par les listes du backend.
class Page<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  const Page(this.items, this.total, this.page, this.limit);
}

class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(
    String email,
    String pin,
    String role, {
    double? lat,
    double? lng,
  }) async {
    final data = await _api.post(
      '/api/auth/login',
      body: {
        'email': email,
        'pin': pin,
        'role': role,
        // Coordonnees GPS optionnelles — tracabilite connexion agent
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    ) as Map<String, dynamic>;
    await _api.saveTokens(
      data['token'] as String,
      data['refreshToken'] as String,
    );
    return data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async =>
      await _api.get('/api/auth/me') as Map<String, dynamic>;

  Future<void> logout() async {
    final refresh = await _api.readRefreshToken();
    try {
      if (refresh != null) {
        await _api.post('/api/auth/logout', body: {'refreshToken': refresh});
      }
    } catch (_) {
      // Déconnexion locale même si l'appel échoue.
    }
    await _api.clearTokens();
  }

  /// Inscription citoyen.
  /// Retourne `{ user: {...}, verificationUrl?: '...', token, refreshToken }`.
  /// Un token est émis immédiatement (accès bloqué par emailVerified=false côté router).
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String? telephone,
    String pin,
  ) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'pin': pin,
    };
    if (telephone != null && telephone.isNotEmpty) body['telephone'] = telephone;
    final data = await _api.post(
      '/api/auth/register',
      body: body,
    ) as Map<String, dynamic>;
    // Sauvegarder les tokens pour pouvoir appeler /me après vérification
    await _api.saveTokens(
      data['token'] as String,
      data['refreshToken'] as String,
    );
    return data; // { user: {...}, verificationUrl?: '...' }
  }

  /// Renvoie le mail de vérification.
  Future<Map<String, dynamic>> resendVerification(String email) async =>
      await _api.post('/api/auth/resend-verification',
          body: {'email': email}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final data = await _api.post(
      '/api/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    ) as Map<String, dynamic>;
    // Backend returns publicUser directly (wrapped by ok() helper)
    return data;
  }

  /// Création d'un compte agent par l'admin (rôle POLICE).
  Future<Map<String, dynamic>> createAgent({
    required String name,
    required String email,
    required String telephone,
    required String badge,
    required String rank,
    required String department,
    required String password,
  }) async {
    final data = await _api.post(
      '/api/officers',
      body: {
        'name': name,
        'email': email,
        'telephone': telephone,
        'badgeNumber': badge,
        'grade': rank,
        'departement': department,
        'pin': password,
      },
    ) as Map<String, dynamic>;
    return data;
  }

  /// Upload photo de profil (base64 ≤ 2 Mo).
  Future<Map<String, dynamic>> uploadPhoto(
    String imageBase64,
    String mimeType,
  ) async {
    return await _api.post('/api/auth/profile/photo', body: {
      'imageBase64': imageBase64,
      'mimeType': mimeType,
    }) as Map<String, dynamic>;
  }

  Future<bool> hasSession() => _api.hasAccessToken();

  /// Enregistre (ou révoque si null) le token FCM pour les notifications push.
  Future<void> updateFcmToken(String? token) async {
    await _api.put('/api/auth/fcm-token', body: {'token': token});
  }
}

class InfractionRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<InfractionType>> list() async {
    final data = await _api.get('/api/infractions') as List<dynamic>;
    return data
        .map((e) => infractionFromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class FineRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Page<FineModel>> list({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _api.get('/api/fines', query: {
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    }) as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => fineFromJson(e as Map<String, dynamic>))
        .toList();
    return Page(
      items,
      (data['total'] as num).toInt(),
      (data['page'] as num).toInt(),
      (data['limit'] as num).toInt(),
    );
  }

  Future<FineModel> getById(String id) async =>
      fineFromJson(await _api.get('/api/fines/$id') as Map<String, dynamic>);

  Future<FineModel> create(Map<String, dynamic> body) async =>
      fineFromJson(await _api.post('/api/fines', body: body) as Map<String, dynamic>);

  /// Soumet plusieurs amendes (un PV par infraction) via des appels séquentiels.
  /// Retourne les modèles des amendes créées.
  Future<List<FineModel>> createBatch(
      List<Map<String, dynamic>> fines) async {
    final results = <FineModel>[];
    for (final body in fines) {
      results.add(await create(body));
    }
    return results;
  }

  Future<Map<String, dynamic>> pay(
    String fineId,
    String operateur,
    String telephone,
  ) async =>
      await _api.post('/api/fines/$fineId/pay',
          body: {'operateur': operateur, 'telephone': telephone}) as Map<String, dynamic>;

  Future<String> pdfUrl(String fineId) async {
    final data =
        await _api.get('/api/fines/$fineId/pdf') as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<Page<FineModel>> listAdmin({
    String? status,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 25,
  }) async {
    final data = await _api.get('/api/fines', query: {
      if (status != null) 'status': status,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      'page': page,
      'limit': limit,
    }) as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => fineFromJson(e as Map<String, dynamic>))
        .toList();
    return Page(
      items,
      (data['total'] as num).toInt(),
      (data['page'] as num).toInt(),
      (data['limit'] as num).toInt(),
    );
  }

  Future<void> updateStatus(String fineId, String status) async {
    await _api.patch('/api/fines/$fineId/status', body: {'status': status});
  }
}

class OfficerRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Page<OfficerModel>> list({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final data = await _api.get('/api/officers', query: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    }) as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => officerFromJson(e as Map<String, dynamic>))
        .toList();
    return Page(
      items,
      (data['total'] as num).toInt(),
      (data['page'] as num).toInt(),
      (data['limit'] as num).toInt(),
    );
  }

  Future<void> create(Map<String, dynamic> body) =>
      _api.post('/api/officers', body: body);

  Future<void> update(String id, Map<String, dynamic> body) =>
      _api.patch('/api/officers/$id', body: body);

  /// Import en masse depuis un contenu CSV.
  /// Retourne { created, skipped, errors, credentials }.
  Future<Map<String, dynamic>> importCsv(String csvContent) async =>
      await _api.post('/api/officers/import-csv',
          body: {'csvContent': csvContent}) as Map<String, dynamic>;

  /// Historique connexions/déconnexions d'un agent.
  /// Retourne { items: [...], total }.
  Future<Map<String, dynamic>> getActivity(
    String officerId, {
    int page = 1,
    int limit = 50,
  }) async =>
      await _api.get('/api/officers/$officerId/activity', query: {
        'page': page,
        'limit': limit,
      }) as Map<String, dynamic>;
}

class PaymentRepository {
  final ApiClient _api = ApiClient.instance;

  /// Initier un paiement Mobile Money. Retourne { paymentUrl, reference }.
  Future<Map<String, dynamic>> initiateMomo({
    required String fineId,
    required String operateur, // 'MTN' | 'AIRTEL'
    required String telephone,
  }) async {
    return await _api.post('/api/payments/initiate', body: {
      'fineId': fineId,
      'operateur': operateur,
      'telephone': telephone,
    }) as Map<String, dynamic>;
  }

  /// Enregistrer un paiement Trésor public. Retourne { paymentId, reference }.
  Future<Map<String, dynamic>> recordTresor({
    required String fineId,
    required String quittanceNumero,
    String? quittanceDate,
    String? agentTresor,
  }) async {
    return await _api.post('/api/payments/tresor', body: {
      'fineId': fineId,
      'quittanceNumero': quittanceNumero,
      if (quittanceDate != null) 'quittanceDate': quittanceDate,
      if (agentTresor != null && agentTresor.isNotEmpty) 'agentTresor': agentTresor,
    }) as Map<String, dynamic>;
  }

  /// Reçu de paiement (paiement + répartition + fine).
  Future<Map<String, dynamic>> receipt(String paymentId) async =>
      await _api.get('/api/payments/receipt/$paymentId') as Map<String, dynamic>;
}

class NotificationRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Page<NotificationModel>> list({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final data = await _api.get('/api/notifications', query: {
      'page': page,
      'limit': limit,
      if (unreadOnly) 'unreadOnly': true,
    }) as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => notificationFromJson(e as Map<String, dynamic>))
        .toList();
    return Page(
      items,
      (data['total'] as num).toInt(),
      (data['page'] as num).toInt(),
      (data['limit'] as num).toInt(),
    );
  }

  Future<void> markRead(String id) =>
      _api.patch('/api/notifications/$id/read');
}

class DriverRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> search({String? plate, String? license}) async {
    return await _api.get('/api/drivers', query: {
      if (plate != null) 'plate': plate,
      if (license != null) 'license': license,
    }) as Map<String, dynamic>;
  }
}

class UserRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Page<UserModel>> listUsers({
    String? role,
    bool? actif,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _api.get('/api/admin/users', query: {
      'page': page,
      'limit': limit,
      if (role != null) 'role': role,
      if (actif != null) 'actif': actif,
      if (search != null && search.isNotEmpty) 'search': search,
    }) as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return Page(
      items,
      (data['total'] as num).toInt(),
      (data['page'] as num).toInt(),
      (data['limit'] as num).toInt(),
    );
  }

  Future<UserModel> getUserById(String id) async {
    final data = await _api.get('/api/admin/users/$id') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> setUserStatus(String id, bool actif) async {
    await _api.patch('/api/admin/users/$id/status', body: {'actif': actif});
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/api/admin/users/$id');
  }
}

class StatsRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> officerStats() async =>
      await _api.get('/api/stats/me') as Map<String, dynamic>;

  Future<Map<String, dynamic>> adminStats() async =>
      await _api.get('/api/stats/admin') as Map<String, dynamic>;

  Future<Map<String, dynamic>> revenue({String? from, String? to}) async =>
      await _api.get('/api/stats/revenue', query: {
        if (from != null) 'dateFrom': from,
        if (to != null) 'dateTo': to,
      }) as Map<String, dynamic>;

  Future<List<dynamic>> heatmap() async =>
      await _api.get('/api/stats/infractions/heatmap') as List<dynamic>;
}
