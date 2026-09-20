// lib/screens/schedule_screen.dart
// Tabbed weekly schedule view — one tab per day from GET /api/v1/schedules.
// Auto-selects today's tab. Requires SingleTickerProviderStateMixin for TabController.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../models/schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  ScheduleData? _schedule;
  late TabController _tabController;
  bool _tabControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getSchedule();
      if (!mounted) return;
      if (_tabControllerInitialized) {
        _tabController.dispose();
      }
      _tabController = TabController(
        length: data.weeklySchedule.length,
        vsync: this,
        initialIndex: _getTodayIndex(data.weeklySchedule),
      );
      _tabControllerInitialized = true;
      setState(() {
        _schedule = data;
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

  /// Returns the index of today's day in [days], or 0 if not found.
  int _getTodayIndex(List<DaySchedule> days) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = weekdays[DateTime.now().weekday - 1];
    final idx = days.indexWhere((d) => d.day == today);
    return idx == -1 ? 0 : idx;
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

  String _formatTime(dynamic t) {
    if (t == null) return '?';
    final str = t.toString().trim();
    final parts = str.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final min = parts[1];
      if (hour != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$h12:$min $period';
      }
      return '${parts[0]}:${parts[1]}';
    }
    return str;
  }

  @override
  void dispose() {
    if (_tabControllerInitialized) _tabController.dispose();
    super.dispose();
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSchedule,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_schedule == null || _schedule!.weeklySchedule.isEmpty) {
      return const Center(child: Text('No schedule data available.'));
    }

    final days = _schedule!.weeklySchedule;
    final summary = _schedule!.summary;

    return Column(
      children: [
        // Summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
          child: Row(
            children: [
              const Icon(Icons.school, size: 16, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${summary["total_subjects"] ?? "—"} subjects · '
                  '${summary["total_units"] ?? "—"} units · '
                  '${summary["school_year"] ?? ""} '
                  '${summary["semester"] ?? ""} Sem',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _schedule!.student['name'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Day tabs
        Material(
          color: Colors.white,
          elevation: 1,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1565C0),
            indicatorWeight: 3,
            tabs: days
                .map((d) => Tab(text: d.day.substring(0, 3).toUpperCase()))
                .toList(),
          ),
        ),

        // Day content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: days.map(_buildDayView).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView(DaySchedule day) {
    if (day.classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.weekend, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No classes on ${day.day}.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: day.classes.length,
      itemBuilder: (ctx, i) {
        final c = day.classes[i];
        final code = (c['subject_code'] as String? ?? 'XX');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
              child: Text(
                code.length >= 2 ? code.substring(0, 2) : code,
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            isThreeLine: true,
            title: Text(
              c['subject_name'] as String? ?? code,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatTime(c["time_start"])} – ${_formatTime(c["time_end"])}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        c['room'] as String? ?? '—',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: c['instructor'] != null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 85),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(height: 2),
                        Text(
                          c['instructor'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
