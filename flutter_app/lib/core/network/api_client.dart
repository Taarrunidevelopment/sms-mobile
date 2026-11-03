import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ApiProblemException implements Exception {
  final String title;
  final String type;
  final int status;
  final String? detail;

  ApiProblemException({
    required this.title,
    required this.type,
    required this.status,
    this.detail,
  });

  @override
  String toString() => title.isNotEmpty ? title : 'API Error ($status)';
}

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  static const String baseUrl = 'https://northfield.200-141-4-40.sslip.io';
  static const String apiPrefix = '/api/v1';

  // Use an in-memory CookieJar to preserve the CSRF and session cookies.
  final CookieJar _cookieJar = CookieJar();
  Dio? _dio;

  void init() {
    _dio ??= _createDio();
  }

  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: '$baseUrl$apiPrefix/',
      contentType: 'application/json',
      followRedirects: true,
    ));
    // Keep platform TLS certificate validation enabled.
    dio.interceptors.add(CookieManager(_cookieJar));
    return dio;
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final dio = _dio ??= _createDio();

    try {
      final options = Options(method: method);

      final isCsrfEndpoint = path == '/auth/csrf' || path == 'auth/csrf';
      final mutating = ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase());

      // Fetch first, then fail closed if the server did not set its CSRF cookie.
      if (!isCsrfEndpoint) {
        var csrfCookie = await _csrfCookie();
        if (csrfCookie == null || csrfCookie.value.isEmpty) {
          await fetchCsrf();
          csrfCookie = await _csrfCookie();
        }
        if (csrfCookie == null || csrfCookie.value.isEmpty) {
          throw ApiProblemException(
            title: 'The school server did not provide a security token. Please refresh and try again.',
            type: 'csrf-missing',
            status: 403,
          );
        }
        options.headers = {'X-CSRFToken': csrfCookie.value};
      }
      if (mutating) {
        options.headers ??= {};
        options.headers!.addAll({
          'Origin': baseUrl,
          'Referer': '$baseUrl/',
        });
      }

      final res = await dio.request(
        path.startsWith('/') ? path.substring(1) : path,
        data: body,
        queryParameters: queryParams,
        options: options,
      );

      if (res.statusCode == 204) return null;
      return res.data;
    } on ApiProblemException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiProblemException(
          title: data['title']?.toString() ?? 'Error ${e.response?.statusCode}',
          type: data['type']?.toString() ?? 'error',
          status: (data['status'] as num?)?.toInt() ?? e.response?.statusCode ?? 500,
          detail: data['detail']?.toString(),
        );
      }
      
      throw ApiProblemException(
        title: 'Request failed (${e.response?.statusCode})',
        type: 'http-error',
        status: e.response?.statusCode ?? 500,
        detail: e.toString(),
      );
    }
  }

  // Auth
  Future<void> fetchCsrf() async {
    await request('/auth/csrf', method: 'GET');
    final csrfCookie = await _csrfCookie();
    if (csrfCookie == null || csrfCookie.value.isEmpty) {
      throw ApiProblemException(
        title: 'The school server did not provide a security token. Please refresh and try again.',
        type: 'csrf-missing',
        status: 403,
      );
    }
  }

  Future<Cookie?> _csrfCookie() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse('$baseUrl$apiPrefix/'));
    for (final cookie in cookies) {
      if (cookie.name == '__Host-csrftoken' || cookie.name == 'csrftoken') {
        return cookie;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> login(String identifier, String password, {bool remember = true}) async {
    await fetchCsrf();
    final res = await request(
      '/auth/login',
      method: 'POST',
      body: {
        'identifier': identifier.trim(),
        'password': password,
        'remember': remember,
      },
    );
    return res is Map<String, dynamic> ? res : {'status': 'signed_in'};
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await request('/me', method: 'GET');
    return res as Map<String, dynamic>;
  }
}
