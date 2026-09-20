// lib/models/announcement.dart
// Type-safe model for the GET /api/v1/announcements response items.

class Announcement {
  final int id;
  final String title;
  final String body;
  final String category;
  final String priority;
  final bool isPinned;
  final String? expiresAt;
  final Map<String, dynamic>? user; // poster: { id, name, role }
  final String createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.isPinned,
    this.expiresAt,
    this.user,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id:        json['id'] as int,
      title:     json['title'] as String,
      body:      json['body'] as String,
      category:  json['category'] as String,
      priority:  json['priority'] as String? ?? 'medium',
      isPinned:  json['is_pinned'] as bool? ?? false,
      expiresAt: json['expires_at'] as String?,
      user:      json['user'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
    );
  }
}
