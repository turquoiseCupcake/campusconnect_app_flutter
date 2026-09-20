import "package:dio/dio.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../config.dart";
import "../models/announcement.dart";
import "../models/event.dart";
import "../models/schedule.dart";
// navigatorKey is defined in main.dart
import "../main.dart" show navigatorKey;

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token != null) {
      options.headers["Authorization"] = "Bearer $token";
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("auth_token");
      navigatorKey.currentState?.pushNamedAndRemoveUntil("/login", (r) => false);
    }
    handler.next(err);
  }
}

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
      headers: {"Accept": "application/json", "Content-Type": "application/json"},
    ));
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ── Announcements ─────────────────────────────────────────
  Future<List<Announcement>> getAnnouncements({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params["category"] = category;
    final r = await _dio.get("/announcements", queryParameters: params);
    return (r.data["data"] as List).map((j) => Announcement.fromJson(j)).toList();
  }

  // ── Events ────────────────────────────────────────────────
  Future<List<Event>> getEvents({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params["category"] = category;
    final r = await _dio.get("/events", queryParameters: params);
    return (r.data["data"] as List).map((j) => Event.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> rsvpToEvent(int eventId) async {
    final r = await _dio.post("/events/$eventId/rsvp");
    return r.data["data"] as Map<String, dynamic>;
  }

  // ── Schedule ──────────────────────────────────────────────
  Future<ScheduleData> getSchedule() async {
    final r = await _dio.get("/schedules");
    return ScheduleData.fromJson(r.data["data"]);
  }

  // ── Notifications ─────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) async {
    final params = <String, dynamic>{};
    if (unreadOnly) params["unread"] = "true";
    final r = await _dio.get("/notifications", queryParameters: params);
    return r.data["data"] as Map<String, dynamic>;
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.patch("/notifications/$id/read");
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete("/notifications/$id");
  }
}
