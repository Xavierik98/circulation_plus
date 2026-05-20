import '../shared/models/fine_model.dart';
import '../shared/models/officer_model.dart';
import '../shared/models/notification_model.dart';
import '../shared/models/infraction_model.dart';
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
    String role,
  ) async {
    final data = await _api.post(
      '/api/auth/login',
      body: {'email': email, 'pin': pin, 'role': role},
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

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String telephone,
    String pin,
  ) async {
    final data = await _api.post(
      '/api/auth/register',
      body: {
        'name': name,
        'email': email,
        'telephone': telephone,
        'pin': pin,
      },
    ) as Map<String, dynamic>;
    await _api.saveTokens(
      data['token'] as String,
      data['refreshToken'] as String,
    );
    return data['user'] as Map<String, dynamic>;
  }

  Future<bool> hasSession() => _api.hasAccessToken();
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

class StatsRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> revenue({String? from, String? to}) async =>
      await _api.get('/api/stats/revenue', query: {
        if (from != null) 'dateFrom': from,
        if (to != null) 'dateTo': to,
      }) as Map<String, dynamic>;

  Future<List<dynamic>> heatmap() async =>
      await _api.get('/api/stats/infractions/heatmap') as List<dynamic>;
}
