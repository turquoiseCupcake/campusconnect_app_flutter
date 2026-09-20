// lib/models/notification.dart
// Named AppNotification to avoid conflict with Flutter's Notification class.

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id:        json['id'] as int,
        title:     json['title'] as String,
        message:   json['message'] as String,
        type:      json['type'] as String,
        isRead:    json['is_read'] as bool? ?? false,
        readAt:    json['read_at'] as String?,
        createdAt: json['created_at'] as String,
      );

  /// Returns a copy with [isRead] set to true and [readAt] set to [readAtTime].
  AppNotification copyWithRead(String readAtTime) => AppNotification(
        id:        id,
        title:     title,
        message:   message,
        type:      type,
        isRead:    true,
        readAt:    readAtTime,
        createdAt: createdAt,
      );
}
