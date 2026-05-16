import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

/// Erreur métier remontée par le backend ({ success:false, error, code }).
class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;
  ApiException(this.message, this.code, this.statusCode);

  @override
  String toString() => message;
}

/// Client HTTP unique : ajoute le Bearer token, rafraîchit sur 401, et
/// déballe l'enveloppe { success, data } du backend Circulation+.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(
            key: AppConstants.secureAccessToken,
          );
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthRoute =
              error.requestOptions.path.contains('/api/auth/');
          if (error.response?.statusCode == 401 &&
              !isAuthRoute &&
              !_isRetry(error.requestOptions)) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                final clone = await _retry(error.requestOptions);
                return handler.resolve(clone);
              } catch (_) {
                // Retombe sur l'erreur d'origine.
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isRetry(RequestOptions options) =>
      options.extra['__retried'] == true;

  Future<Response<dynamic>> _retry(RequestOptions options) {
    options.extra['__retried'] = true;
    return _dio.fetch(options);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.read(
      key: AppConstants.secureRefreshToken,
    );
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      await saveTokens(
        data['token'] as String,
        data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(
      key: AppConstants.secureAccessToken,
      value: access,
    );
    await _storage.write(
      key: AppConstants.secureRefreshToken,
      value: refresh,
    );
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.secureAccessToken);
    await _storage.delete(key: AppConstants.secureRefreshToken);
  }

  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.secureRefreshToken);

  Future<bool> hasAccessToken() async {
    final t = await _storage.read(key: AppConstants.secureAccessToken);
    return t != null && t.isNotEmpty;
  }

  /// Exécute une requête et renvoie le contenu de `data` (enveloppe déballée).
  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      final payload = res.data;
      if (payload is Map && payload['success'] == true) {
        return payload['data'];
      }
      throw ApiException(
        (payload is Map ? payload['error'] as String? : null) ??
            'Réponse invalide',
        (payload is Map ? payload['code'] as String? : null) ?? 'BAD_RESPONSE',
        res.statusCode ?? 0,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['success'] == false) {
        throw ApiException(
          data['error'] as String? ?? 'Erreur serveur',
          data['code'] as String? ?? 'SERVER_ERROR',
          e.response?.statusCode ?? 0,
        );
      }
      throw ApiException(
        e.message ?? 'Erreur réseau',
        'NETWORK_ERROR',
        e.response?.statusCode ?? 0,
      );
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      request('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) =>
      request('POST', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) =>
      request('PATCH', path, body: body);
}
