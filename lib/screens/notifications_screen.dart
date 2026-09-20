// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onNotificationRead; // callback to update HomeScreen badge
  const NotificationsScreen({super.key, this.onNotificationRead});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await ApiService().getNotifications();
      final list = (result["notifications"] as List)
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() {
        _notifications = list;
        _unreadCount = result["unread_count"] as int;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data["message"] ?? "Could not load notifications.";
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return; // already read — do nothing
    try {
      await ApiService().markNotificationRead(n.id);
      setState(() {
        // Optimistic update — update local list without re-fetching
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifications[idx] = AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true, // mark as read
            readAt: DateTime.now().toIso8601String(),
            createdAt: n.createdAt,
          );
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
      });
      widget.onNotificationRead?.call(); // update HomeScreen badge
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.response?.data["message"] ?? "Failed to mark as read."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(
              onPressed: _loadNotifications,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Notifications ($_unreadCount unread)")),
      body: _notifications.isEmpty
          ? const Center(child: Text("No notifications."))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) {
                final n = _notifications[i];
                return ListTile(
                  tileColor: n.isRead ? null : Colors.blue.shade50,
                  leading: Icon(
                    n.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: n.isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight:
                          n.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: n.isRead
                      ? null
                      : const Icon(Icons.circle, color: Colors.blue, size: 10),
                  onTap: () => _markAsRead(n),
                );
              },
            ),
    );
  }
}
