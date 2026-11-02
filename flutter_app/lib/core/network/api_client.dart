import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiProblemException implements Exception {
  const ApiProblemException({required this.title, required this.type, required this.status, this.detail, this.requestId});

  final String title;
  final String type;
  final int status;
  final String? detail;
  final String? requestId;

  @override
  String toString() {
    final heading = title.isNotEmpty ? title : 'Request failed ($status)';
    final explanation = detail?.trim();
    return explanation == null || explanation.isEmpty || explanation == heading
        ? heading
        : '$heading\n$explanation';
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
  static const String _cookieStorageKey = 'northfield.parent.cookies.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20);
  final Map<String, String> _cookies = {};
  String? _csrfToken;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final saved = await _storage.read(key: _cookieStorageKey);
    if (saved != null && saved.isNotEmpty) {
      final decoded = jsonDecode(saved);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          _cookies[entry.key.toString()] = entry.value.toString();
        }
      }
    }
    _csrfToken = _cookieEndingWith('csrftoken');
    _initialized = true;
  }

  String? _cookieEndingWith(String suffix) {
    for (final entry in _cookies.entries) {
      if (entry.key.endsWith(suffix)) return entry.value;
    }
    return null;
  }

  Future<void> _persistCookies() async {
    await _storage.write(key: _cookieStorageKey, value: jsonEncode(_cookies));
  }

  Future<void> _saveResponseCookies(HttpHeaders headers) async {
    final values = headers[HttpHeaders.setCookieHeader] ?? const <String>[];
    var changed = false;
    for (final raw in values) {
      final cookie = Cookie.fromSetCookieValue(raw);
      final expired = (cookie.maxAge != null && cookie.maxAge! <= 0) || (cookie.expires?.isBefore(DateTime.now()) ?? false);
      if (expired) {
        changed = _cookies.remove(cookie.name) != null || changed;
      } else {
        _cookies[cookie.name] = cookie.value;
        if (cookie.name.endsWith('csrftoken')) _csrfToken = cookie.value;
        changed = true;
      }
    }
    if (changed) await _persistCookies();
  }

  String _cookieHeader() => _cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');

  Uri _uri(String path, Map<String, String>? queryParams) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$apiPrefix$cleanPath');
    return queryParams == null || queryParams.isEmpty ? uri : uri.replace(queryParameters: queryParams);
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    await initialize();
    return _perform(path, method: method, body: body, queryParams: queryParams, headers: headers);
  }

  Future<dynamic> uploadMultipart(
    String path, {
    required Map<String, String> fields,
    String? filePath,
    String? fileField,
    String? fileName,
    required String idempotencyKey,
  }) async {
    await initialize();
    final boundary = 'northfield-${DateTime.now().microsecondsSinceEpoch}';
    return _perform(
      path,
      method: 'POST',
      headers: {
        HttpHeaders.contentTypeHeader: 'multipart/form-data; boundary=$boundary',
        'Idempotency-Key': idempotencyKey,
      },
      bodyStream: () => _multipartBody(boundary, fields, filePath, fileField, fileName),
    );
  }

  Stream<List<int>> _multipartBody(String boundary, Map<String, String> fields, String? filePath, String? fileField, String? fileName) async* {
    for (final entry in fields.entries) {
      yield utf8.encode('--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n');
    }
    if (filePath != null && fileField != null) {
      final safeName = (fileName ?? File(filePath).uri.pathSegments.last).replaceAll('"', '_');
      final mime = _mimeType(safeName);
      yield utf8.encode('--$boundary\r\nContent-Disposition: form-data; name="$fileField"; filename="$safeName"\r\nContent-Type: $mime\r\n\r\n');
      yield* File(filePath).openRead();
      yield utf8.encode('\r\n');
    }
    yield utf8.encode('--$boundary--\r\n');
  }

  String _mimeType(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }

  Future<dynamic> _perform(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Stream<List<int>> Function()? bodyStream,
    bool retryCsrf = true,
  }) async {
    final verb = method.toUpperCase();
    final mutating = const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(verb);
    if (mutating && _csrfToken == null) await fetchCsrf();

    final uri = _uri(path, queryParams);
    final req = await _httpClient.openUrl(verb, uri).timeout(const Duration(seconds: 30));
    req.headers.set(HttpHeaders.acceptHeader, 'application/json, application/problem+json');
    final cookies = _cookieHeader();
    if (cookies.isNotEmpty) req.headers.set(HttpHeaders.cookieHeader, cookies);
    if (headers != null) {
      headers.forEach((key, value) => req.headers.set(key, value));
    }
    if (mutating) {
      req.headers.set('Origin', Uri.parse(baseUrl).origin);
      final token = _csrfToken ?? _cookieEndingWith('csrftoken');
      if (token == null || token.isEmpty) {
        throw const ApiProblemException(title: 'The school server did not provide a security token. Try again.', type: 'csrf-missing', status: 403);
      }
      req.headers.set('X-CSRFToken', token);
    }

    if (bodyStream != null) {
      await req.addStream(bodyStream());
    } else if (body != null) {
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.add(utf8.encode(jsonEncode(body)));
    }

    final response = await req.close().timeout(const Duration(seconds: 60));
    await _saveResponseCookies(response.headers);
    final bytes = await response.fold<List<int>>(<int>[], (previous, chunk) => previous..addAll(chunk));
    final text = utf8.decode(bytes, allowMalformed: true);
    dynamic decoded;
    if (text.trim().isNotEmpty) {
      try { decoded = jsonDecode(text); } catch (_) { decoded = text; }
    }

    if (response.statusCode >= 400) {
      final problem = _problem(decoded, response.statusCode, response.headers.value('x-request-id'));
      if (retryCsrf && mutating && response.statusCode == 403 && problem.type.endsWith('/csrf-failed')) {
        await fetchCsrf();
        return _perform(path, method: method, body: body, queryParams: queryParams, headers: headers, bodyStream: bodyStream, retryCsrf: false);
      }
      throw problem;
    }
    if (response.statusCode == 204 || text.trim().isEmpty) return null;
    return decoded;
  }

  ApiProblemException _problem(dynamic value, int status, String? requestId) {
    if (value is Map) {
      final title = value['title']?.toString().trim();
      final detail = value['detail']?.toString();
      return ApiProblemException(
        title: title == null || title.isEmpty ? 'Request failed ($status)' : title,
        type: value['type']?.toString() ?? 'http-error',
        status: (value['status'] as num?)?.toInt() ?? status,
        detail: detail,
        requestId: requestId,
      );
    }
    return ApiProblemException(
      title: value is String && value.trim().isNotEmpty ? value.trim() : 'Request failed ($status)',
      type: 'http-error',
      status: status,
      requestId: requestId,
    );
  }

  Future<void> fetchCsrf() async {
    await initialize();
    await _perform('/auth/csrf', method: 'GET', retryCsrf: false);
    _csrfToken ??= _cookieEndingWith('csrftoken');
    if (_csrfToken == null || _csrfToken!.isEmpty) {
      throw const ApiProblemException(title: 'The school server did not provide a security token. Try again.', type: 'csrf-missing', status: 403);
    }
  }

  Future<void> clearSession() async {
    await initialize();
    _cookies.remove('__Host-sid');
    _cookies.remove('sid');
    _cookies.remove('__Host-csrftoken');
    _cookies.remove('csrftoken');
    _csrfToken = null;
    await _persistCookies();
  }

  Future<void> logout() async {
    await request('/auth/logout', method: 'POST');
    await clearSession();
  }

  Future<dynamic> fetchBranding() => request('/school/branding');
  Future<dynamic> login(String identifier, String password, {bool remember = true}) => request('/auth/login', method: 'POST', body: {'identifier': identifier.trim(), 'password': password, 'remember': remember});
  Future<dynamic> verifyTwoFactor(String code, {bool trustDevice = false}) => request('/auth/two-factor/verify', method: 'POST', body: {'code': code, 'trust_device': trustDevice});
  Future<dynamic> setupTwoFactor() => request('/auth/two-factor/setup', method: 'POST');
  Future<dynamic> confirmTwoFactorSetup(String code) => request('/auth/two-factor/setup/confirm', method: 'POST', body: {'code': code});
  Future<dynamic> verifyActivation(String phone, String code) => request('/auth/activation/verify', method: 'POST', body: {'phone': phone.trim(), 'code': code.trim()});
  Future<dynamic> completeActivation(String password, bool acceptPolicy) => request('/auth/activation/complete', method: 'POST', body: {'password': password, 'accept_policy': acceptPolicy});
  Future<dynamic> requestPasswordReset(String identifier) => request('/auth/password-reset', method: 'POST', body: {'identifier': identifier.trim()});
  Future<dynamic> getMe() => request('/me');
  Future<dynamic> getChildren() => request('/portal/children');
  Future<dynamic> getTodayAttendance() => request('/portal/attendance/today');
  Future<dynamic> getChildProfile(String id) => request('/portal/children/$id/profile');
  Future<dynamic> getChildAttendance(String id, String month) => request('/portal/children/$id/attendance', queryParams: {'month': month});
  Future<dynamic> getCalendar(String id, String from, String to) => request('/portal/children/$id/calendar', queryParams: {'from': from, 'to': to});
  Future<dynamic> getWorkingDays(String id, String from, String to) => request('/portal/children/$id/working-days', queryParams: {'from': from, 'to': to});
  Future<dynamic> getLeaveRequests(String id) => request('/portal/children/$id/leave-requests');
  Future<dynamic> getLeaveDocument(String studentId, String requestId) => request('/portal/children/$studentId/leave-requests/$requestId/document');
  Future<dynamic> createLeaveRequest(String id, {required String startsOn, required String endsOn, required String reason, String? filePath, String? fileName, required String idempotencyKey}) => uploadMultipart('/portal/children/$id/leave-requests', fields: {'starts_on': startsOn, 'ends_on': endsOn, 'reason': reason}, filePath: filePath, fileField: filePath == null ? null : 'document', fileName: fileName, idempotencyKey: idempotencyKey);
  Future<dynamic> withdrawLeaveRequest(String studentId, String requestId, int version) => request('/portal/children/$studentId/leave-requests/$requestId/withdraw', method: 'POST', body: {'version': version});
  Future<dynamic> getNotifications({int page = 1, int pageSize = 25, bool unread = false}) => request('/notifications', queryParams: {'page': '$page', 'page_size': '$pageSize', 'unread': '$unread'});
  Future<dynamic> getUnreadCount() => request('/notifications/unread-count');
  Future<dynamic> markNotificationRead(String id) => request('/notifications/$id/read', method: 'POST');
  Future<dynamic> markAllNotificationsRead() => request('/notifications/read-all', method: 'POST');
  Future<dynamic> getAlertPreferences() => request('/me/alerts');
  Future<dynamic> saveAlertCategory(String category, bool push, bool email) => request('/me/alerts/${Uri.encodeComponent(category)}', method: 'PUT', body: {'push': push, 'email': email});
  Future<dynamic> getSessions() => request('/me/sessions');
  Future<dynamic> revokeSession(String id) => request('/me/sessions/$id', method: 'DELETE');
  Future<dynamic> revokeOtherSessions() => request('/me/sessions/revoke-others', method: 'POST');
  Future<dynamic> changePassword(String current, String next) => request('/me/password', method: 'POST', body: {'current_password': current, 'new_password': next});
  Future<dynamic> requestEmailChange(String email, String password) => request('/me/email-change', method: 'POST', body: {'new_email': email.trim(), 'password': password});
  Future<dynamic> savePreferences(String theme, {String density = 'comfortable', String? lastArea = 'parent'}) => request('/me/preferences', method: 'PUT', body: {'density': density, 'last_area': lastArea, 'theme': theme});
}
