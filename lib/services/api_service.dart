// lib/services/api_service.dart
// Single source of truth for all HTTP calls to the CampusConnect Laravel API.
// Widgets never touch Dio directly — they call methods on ApiService().

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../models/schedule.dart';
// navigatorKey is declared in main.dart and used by the 401 interceptor.
import '../main.dart' show navigatorKey;

// ── Auth Interceptor ──────────────────────────────────────────────────────────
// Runs before every request  → injects the stored Bearer token.
// Runs on every error        → on 401, clears the token and sends the user to /login.

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
    handler.next(options); // proceed with (possibly modified) request
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token is expired or revoked — clear it and redirect to login.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // clear the entire navigation stack
      );
    }
    handler.next(err); // pass error to the calling widget's catch block
  }
}

// ── ApiService Singleton ──────────────────────────────────────────────────────
// One Dio instance shared across the whole app.
// Interceptors are registered once; the connection pool is shared.

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
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

    // Uncomment during debugging to log every request/response.
    // Remove before committing.
    // _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  // ── ANNOUNCEMENTS ───────────────────────────────────────────────────────────

  /// Fetches all announcements.
  /// Optional [category] filter: 'Academic' | 'Administrative' | etc.
  /// Optional [pinned] = true returns only pinned announcements.
  Future<List<Announcement>> getAnnouncements({
    String? category,
    bool? pinned,
  }) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (pinned == true) params['pinned'] = 'true';

    final r = await _dio.get('/announcements', queryParameters: params);
    return (r.data['data'] as List)
        .map((j) => Announcement.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── EVENTS ──────────────────────────────────────────────────────────────────

  /// Fetches all events.
  /// Optional [category] and [status] filters.
  Future<List<Event>> getEvents({
    String? category,
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (status != null) params['status'] = status;

    final r = await _dio.get('/events', queryParameters: params);
    return (r.data['data'] as List)
        .map((j) => Event.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// RSVP the authenticated user to [eventId].
  /// Returns the RSVP data map from the API.
  Future<Map<String, dynamic>> rsvpToEvent(int eventId) async {
    final r = await _dio.post('/events/$eventId/rsvp');
    return r.data['data'] as Map<String, dynamic>;
  }

  // ── SCHEDULE ─────────────────────────────────────────────────────────────────

  /// Fetches the authenticated student's weekly schedule.
  Future<ScheduleData> getSchedule() async {
    final r = await _dio.get('/schedules');
    return ScheduleData.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────────────────────

  /// Fetches notifications for the authenticated user.
  /// Returns `{ "unread_count": N, "notifications": [...] }`.
  /// Set [unreadOnly] = true to filter to unread items only.
  Future<Map<String, dynamic>> getNotifications({
    bool unreadOnly = false,
    String? type,
  }) async {
    final params = <String, dynamic>{};
    if (unreadOnly) params['unread'] = 'true';
    if (type != null) params['type'] = type;

    final r = await _dio.get('/notifications', queryParameters: params);
    return r.data['data'] as Map<String, dynamic>;
  }

  /// Marks notification [notificationId] as read.
  Future<void> markNotificationRead(int notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  /// Deletes notification [notificationId].
  Future<void> deleteNotification(int notificationId) async {
    await _dio.delete('/notifications/$notificationId');
  }
}
