// lib/screens/announcements_screen.dart
// Displays live announcements from GET /api/v1/announcements.
// Three-state pattern: loading → error+retry → list.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../models/announcement.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = data;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_announcements.isEmpty) {
      return const Center(child: Text('No announcements available.'));
    }
    return _buildList();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _announcements.length,
        itemBuilder: (ctx, i) => _AnnouncementCard(announcement: _announcements[i]),
      ),
    );
  }
}

// ── Announcement Card ──────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  Color get _priorityColor {
    switch (announcement.priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Card(
      elevation: a.isPinned ? 3 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: a.isPinned
            ? BorderSide(color: _priorityColor.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _priorityColor.withValues(alpha: 0.15),
                  child: Icon(
                    a.isPinned ? Icons.push_pin : Icons.announcement,
                    size: 18,
                    color: _priorityColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  a.createdAt.substring(0, 10),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Body
            Text(
              a.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 10),

            // Tags row
            Wrap(
              spacing: 6,
              children: [
                _chip(a.category, Colors.blueGrey),
                _chip(a.priority.toUpperCase(), _priorityColor),
                if (a.isPinned) _chip('📌 Pinned', Colors.orange),
                if (a.user != null)
                  _chip('by ${a.user!["name"]}', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
