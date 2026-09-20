// lib/screens/notifications_screen.dart
// Shows live notifications from GET /api/v1/notifications.
// Features: unread count in AppBar, optimistic mark-as-read, badge callback.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  /// Called after a notification is successfully marked as read,
  /// so the HomeScreen can decrement its badge counter.
  final VoidCallback? onNotificationRead;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService().getNotifications();
      if (!mounted) return;
      final list = (result['notifications'] as List)
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList();
      setState(() {
        _notifications = list;
        // Use the server-provided count, NOT _notifications.length
        // (filters may be active that exclude some items)
        _unreadCount = result['unread_count'] as int? ?? 0;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  /// Marks [n] as read — optimistic UI: updates local list without re-fetching.
  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return; // already read — nothing to do
    try {
      await ApiService().markNotificationRead(n.id);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifications[idx] =
              n.copyWithRead(DateTime.now().toIso8601String());
          _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        }
      });
      widget.onNotificationRead?.call(); // update HomeScreen badge
    } on DioException catch (e) {
      if (!mounted) return;
      final msg =
          e.response?.data?['message'] as String? ?? 'Failed to mark as read.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// Deletes [n] — removes from local list immediately.
  Future<void> _delete(AppNotification n) async {
    try {
      await ApiService().deleteNotification(n.id);
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((x) => x.id == n.id);
        if (!n.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 9999);
          widget.onNotificationRead?.call();
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg =
          e.response?.data?['message'] as String? ?? 'Failed to delete.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _friendlyError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Check your WiFi.';
    }
    if (e.response != null) {
      return e.response!.data?['message'] as String? ??
          'Server error (${e.response!.statusCode}).';
    }
    return 'Connection failed. Please try again.';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'announcement':
        return Colors.blue;
      case 'event':
        return Colors.green;
      case 'schedule':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No notifications yet.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, idx) => const Divider(height: 1, indent: 70),
        itemBuilder: (ctx, i) {
          final n = _notifications[i];
          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red.shade400,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete notification?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              return confirmed == true;
            },
            onDismissed: (_) => _delete(n),
            child: ListTile(
              tileColor: n.isRead ? null : Colors.blue.shade50,
              leading: CircleAvatar(
                backgroundColor: _typeColor(n.type).withValues(alpha: 0.12),
                child: Icon(
                  n.isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: _typeColor(n.type),
                  size: 20,
                ),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight:
                      n.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.createdAt.substring(0, 16).replaceAll('T', ' '),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              trailing: n.isRead
                  ? null
                  : const Icon(Icons.circle, color: Colors.blue, size: 10),
              onTap: () => _markAsRead(n),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
