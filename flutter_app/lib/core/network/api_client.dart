import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiProblemException implements Exception {
  const ApiProblemException({
    required this.title,
    required this.type,
    required this.status,
    this.detail,
  });

  final String title;
  final String type;
  final int status;
  final String? detail;

  @override
  String toString() {
    final message = detail?.trim();
    return message == null || message.isEmpty ? title : '$title: $message';
  }
}

typedef JsonMap = Map<String, dynamic>;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://northfield.200-141-4-40.sslip.io',
  );
  static const String apiPrefix = '/api/v1';

  final CookieJar _cookieJar = CookieJar();
  Dio? _dio;

  Dio get _client => _dio ??= _createDio();

  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: '$baseUrl$apiPrefix/',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      contentType: Headers.jsonContentType,
      headers: const {Headers.acceptHeader: 'application/json, application/problem+json'},
    ));
    // Default platform TLS validation stays enabled.
    dio.interceptors.add(CookieManager(_cookieJar));
    return dio;
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    bool retryCsrf = true,
  }) async {
    final csrfEndpoint = path == '/auth/csrf' || path == 'auth/csrf';
    final verb = method.toUpperCase();
    try {
      final requestHeaders = <String, dynamic>{...?headers};
      if (!csrfEndpoint) {
        var csrf = await _csrfCookie();
        if (csrf == null || csrf.value.isEmpty) {
          await fetchCsrf();
          csrf = await _csrfCookie();
        }
        if (csrf == null || csrf.value.isEmpty) {
          throw const ApiProblemException(
            title: 'The school server did not provide a security token. Please refresh and try again.',
            type: 'csrf-missing',
            status: 403,
          );
        }
        requestHeaders['X-CSRFToken'] = csrf.value;
      }
      if (const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(verb)) {
        requestHeaders['Origin'] = Uri.parse(baseUrl).origin;
        requestHeaders['Referer'] = '$baseUrl/';
      }

      final response = await _client.request<dynamic>(
        path.startsWith('/') ? path.substring(1) : path,
        data: body,
        queryParameters: queryParams,
        options: Options(method: verb, headers: requestHeaders),
      );
      return response.statusCode == 204 ? null : response.data;
    } on ApiProblemException {
      rethrow;
    } on DioException catch (error) {
      final problem = _problem(error);
      if (retryCsrf && !csrfEndpoint && problem.status == 403 && problem.type.endsWith('/csrf-failed')) {
        await fetchCsrf();
        return request(
          path,
          method: method,
          body: body,
          queryParams: queryParams,
          headers: headers,
          retryCsrf: false,
        );
      }
      throw problem;
    }
  }

  ApiProblemException _problem(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final data = error.response?.data;
    if (data is Map) {
      return ApiProblemException(
        title: data['title']?.toString() ?? 'Request failed ($status)',
        type: data['type']?.toString() ?? 'http-error',
        status: (data['status'] as num?)?.toInt() ?? status,
        detail: data['detail']?.toString(),
      );
    }
    final detail = error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout
        ? 'Check your internet connection and the school server address.'
        : error.message;
    return ApiProblemException(
      title: status == 0 ? 'Could not connect to the school server.' : 'Request failed ($status)',
      type: 'network-error',
      status: status,
      detail: detail,
    );
  }

  Future<Cookie?> _csrfCookie() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse('$baseUrl$apiPrefix/'));
    for (final cookie in cookies) {
      if (cookie.name == '__Host-csrftoken' || cookie.name == 'csrftoken') return cookie;
    }
    return null;
  }

  Future<void> fetchCsrf() async {
    await request('/auth/csrf', method: 'GET', retryCsrf: false);
    final cookie = await _csrfCookie();
    if (cookie == null || cookie.value.isEmpty) {
      throw const ApiProblemException(
        title: 'The school server did not provide a security token. Please refresh and try again.',
        type: 'csrf-missing',
        status: 403,
      );
    }
  }

  Future<dynamic> fetchBranding() => request('/school/branding');

  Future<dynamic> login(String identifier, String password, {bool remember = true}) async {
    await fetchCsrf();
    return request('/auth/login', method: 'POST', body: {
      'identifier': identifier.trim(),
      'password': password,
      'remember': remember,
    });
  }

  Future<dynamic> verifyTwoFactor(String code, {bool trustDevice = false}) => request(
        '/auth/two-factor/verify',
        method: 'POST',
        body: {'code': code.trim(), 'trust_device': trustDevice},
      );

  Future<dynamic> setupTwoFactor() => request('/auth/two-factor/setup', method: 'POST');

  Future<dynamic> confirmTwoFactorSetup(String code) => request(
        '/auth/two-factor/setup/confirm',
        method: 'POST',
        body: {'code': code.trim()},
      );

  Future<dynamic> requestPasswordReset(String identifier) => request(
        '/auth/password-reset',
        method: 'POST',
        body: {'identifier': identifier.trim()},
      );

  Future<dynamic> verifyActivation(String phone, String code) => request(
        '/auth/activation/verify',
        method: 'POST',
        body: {'phone': phone.trim(), 'code': code.trim()},
      );

  Future<dynamic> completeActivation(String password, {required bool acceptPolicy}) => request(
        '/auth/activation/complete',
        method: 'POST',
        body: {'password': password, 'accept_policy': acceptPolicy},
      );

  Future<dynamic> getMe() => request('/me');
  Future<dynamic> getChildren() => request('/portal/children');
  Future<dynamic> getTodayAttendance() => request('/portal/attendance/today');
  Future<dynamic> getChildProfile(String id) => request('/portal/children/${Uri.encodeComponent(id)}/profile');
  Future<dynamic> getChildAttendance(String id, String month) => request(
        '/portal/children/${Uri.encodeComponent(id)}/attendance',
        queryParams: {'month': month},
      );
  Future<dynamic> getCalendar(String id, String from, String to) => request(
        '/portal/children/${Uri.encodeComponent(id)}/calendar',
        queryParams: {'from': from, 'to': to},
      );
  Future<dynamic> getWorkingDays(String id, String from, String to) => request(
        '/portal/children/${Uri.encodeComponent(id)}/working-days',
        queryParams: {'from': from, 'to': to},
      );
  Future<dynamic> getLeaveRequests(String id) => request('/portal/children/${Uri.encodeComponent(id)}/leave-requests');
  Future<dynamic> createLeaveRequest(
    String id, {
    required String startsOn,
    required String endsOn,
    required String reason,
    File? document,
  }) {
    final idempotencyKey = '${DateTime.now().microsecondsSinceEpoch}-${id.hashCode}';
    return _createLeaveRequest(
      id,
      startsOn: startsOn,
      endsOn: endsOn,
      reason: reason,
      document: document,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<dynamic> _createLeaveRequest(
    String id, {
    required String startsOn,
    required String endsOn,
    required String reason,
    required String idempotencyKey,
    File? document,
  }) async {
    Future<FormData> createBody() async {
      final fields = <String, dynamic>{
        'starts_on': startsOn,
        'ends_on': endsOn,
        'reason': reason,
      };
      if (document != null) {
        fields['document'] = await MultipartFile.fromFile(
          document.path,
          filename: document.uri.pathSegments.isEmpty ? 'attachment' : document.uri.pathSegments.last,
        );
      }
      return FormData.fromMap(fields);
    }

    Future<dynamic> send() async => request(
          '/portal/children/${Uri.encodeComponent(id)}/leave-requests',
          method: 'POST',
          body: await createBody(),
          headers: {'Idempotency-Key': idempotencyKey},
          retryCsrf: false,
        );

    try {
      return await send();
    } on ApiProblemException catch (error) {
      if (error.status != 403 || !error.type.endsWith('/csrf-failed')) rethrow;
      await fetchCsrf();
      return send();
    }
  }

  Future<dynamic> withdrawLeaveRequest(String studentId, String requestId, int version) => request(
        '/portal/children/${Uri.encodeComponent(studentId)}/leave-requests/${Uri.encodeComponent(requestId)}/withdraw',
        method: 'POST',
        body: {'version': version},
      );
  Future<dynamic> getNotifications({int page = 1, int pageSize = 25, bool unread = false}) => request(
        '/notifications',
        queryParams: {'page': page, 'page_size': pageSize, 'unread': unread},
      );
  Future<dynamic> getUnreadCount() => request('/notifications/unread-count');
  Future<dynamic> markNotificationRead(String id) => request('/notifications/${Uri.encodeComponent(id)}/read', method: 'POST');
  Future<dynamic> markAllNotificationsRead() => request('/notifications/read-all', method: 'POST');
  Future<dynamic> getAlertPreferences() => request('/me/alerts');
  Future<dynamic> saveAlertCategory(String category, bool push, bool email) => request(
        '/me/alerts/${Uri.encodeComponent(category)}',
        method: 'PUT',
        body: {'push': push, 'email': email},
      );
  Future<dynamic> getSessions() => request('/me/sessions');
  Future<dynamic> revokeSession(String id) => request('/me/sessions/${Uri.encodeComponent(id)}', method: 'DELETE');
  Future<dynamic> revokeOtherSessions() => request('/me/sessions/revoke-others', method: 'POST');
  Future<dynamic> changePassword(String current, String next) => request('/me/password', method: 'POST', body: {
        'current_password': current,
        'new_password': next,
      });
  Future<dynamic> requestEmailChange(String email, String password) => request('/me/email-change', method: 'POST', body: {
        'new_email': email.trim(),
        'password': password,
      });
  Future<dynamic> savePreferences(String theme, {String density = 'comfortable'}) => request('/me/preferences', method: 'PUT', body: {
        'density': density,
        'last_area': 'parent',
        'theme': theme,
      });

  Future<void> logout() async {
    await request('/auth/logout', method: 'POST');
    await _cookieJar.deleteAll();
  }
}
