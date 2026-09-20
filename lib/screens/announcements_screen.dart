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
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data["message"] ?? "Could not load announcements.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              TextButton(
                onPressed: _loadAnnouncements,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: _announcements.isEmpty
            ? const Center(child: Text('No announcements available.'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _announcements.length,
                itemBuilder: (ctx, i) {
                  final a = _announcements[i];
                  return Card(
                    elevation: a.isPinned ? 3 : 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: a.priority == 'high'
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          a.isPinned ? Icons.push_pin : Icons.announcement,
                          color: a.priority == 'high'
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(a.category),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              if (a.isPinned) const SizedBox(width: 4),
                              if (a.isPinned)
                                const Chip(
                                  label: Text('Pinned'),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Text(
                        a.createdAt.length >= 10
                            ? a.createdAt.substring(0, 10)
                            : a.createdAt,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
