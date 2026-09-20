// lib/screens/schedule_screen.dart
import "package:flutter/material.dart";
import "package:dio/dio.dart";
import "../services/api_service.dart";
import "../models/schedule.dart";

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

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final data = await ApiService().getSchedule();
      setState(() {
        _schedule = data;
        _isLoading = false;
        // Create TabController with one tab per day
        _tabController = TabController(
          length: data.weeklySchedule.length,
          vsync: this,
          // Start on today's tab if possible
          initialIndex: _getTodayIndex(data.weeklySchedule),
        );
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data["message"] ?? "Could not load schedule.";
        _isLoading = false;
      });
    }
  }

  int _getTodayIndex(List<DaySchedule> days) {
    final today = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ][DateTime.now().weekday - 1];
    final idx = days.indexWhere((d) => d.day == today);
    return idx == -1 ? 0 : idx;
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
            TextButton(onPressed: _loadSchedule, child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_schedule == null) return const Center(child: Text("No schedule data."));

    final days = _schedule!.weeklySchedule;
    final summary = _schedule!.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule — ${_schedule!.student["name"]}"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: days.map((d) => Tab(text: d.day.substring(0, 3))).toList(),
        ),
      ),
      body: Column(
        children: [
          // Summary banner
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: Text(
              "${summary["total_subjects"]} subjects · ${summary["total_units"]} units · ${summary["school_year"]} ${summary["semester"]} Sem",
            ),
          ),
          // Day class lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: days.map((day) => _buildDayView(day)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView(DaySchedule day) {
    if (day.classes.isEmpty) {
      return const Center(child: Text("No classes on this day."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: day.classes.length,
      itemBuilder: (ctx, i) {
        final c = day.classes[i];
        final code = c["subject_code"] as String? ?? "";
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(code.length >= 2 ? code.substring(0, 2) : code),
            ),
            title: Text(c["subject_name"] ?? code),
            subtitle: Text("${c["room"]} · ${c["time_start"]}-${c["time_end"]}"),
            trailing: Text(c["instructor"] ?? ""),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_schedule != null) _tabController.dispose();
    super.dispose();
  }
}
