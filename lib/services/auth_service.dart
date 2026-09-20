// lib/services/auth_service.dart
// Identity lifecycle service — Module 14.
// Single source of truth for login, register, me, profile, and logout.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../main.dart' show navigatorKey;

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
    handler.next(err);
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _init();
  }

  late final Dio _dio;

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ── LOGIN ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'];
    await _saveAuthData(data as Map<String, dynamic>);
    return data['user'] as Map<String, dynamic>;
  }

  // ── REGISTER ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
    });
    final data = response.data['data'];
    await _saveAuthData(data as Map<String, dynamic>);
    return data['user'] as Map<String, dynamic>;
  }

  // ── GET CURRENT USER ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    final user = response.data['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user));
    return user;
  }

  // ── LOGOUT ───────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {} // ignore API errors — always clear local state
    await clearAuthData();
  }

  // ── UPDATE PROFILE ───────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? studentId,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (studentId != null) data['student_id'] = studentId;
    final response = await _dio.put('/auth/profile', data: data);
    final user = response.data['data'] as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user));
    return user;
  }

  // ── CACHED USER ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('user_data');
    return json != null ? jsonDecode(json) as Map<String, dynamic> : null;
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token'] as String);
    await prefs.setString('user_data', jsonEncode(data['user']));
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
