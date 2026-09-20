// lib/screens/events_screen.dart
// Displays live events from GET /api/v1/events with RSVP functionality.
// RSVP button shows per-event spinner; refreshes list after RSVP.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../models/event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Event> _events = [];
  // Tracks which event IDs have an RSVP in progress
  final Set<int> _rsvpInProgress = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getEvents();
      if (!mounted) return;
      setState(() {
        _events = data;
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

  Future<void> _rsvp(Event event) async {
    setState(() => _rsvpInProgress.add(event.id));
    try {
      await ApiService().rsvpToEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ RSVP confirmed for "${event.title}"!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEvents(); // refresh to show updated rsvp_count
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message'] as String? ?? 'RSVP failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _rsvpInProgress.remove(event.id));
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
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_events.isEmpty) {
      return const Center(child: Text('No upcoming events.'));
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _events.length,
        itemBuilder: (ctx, i) => _EventCard(
          event: _events[i],
          rsvpInProgress: _rsvpInProgress.contains(_events[i].id),
          onRsvp: () => _rsvp(_events[i]),
        ),
      ),
    );
  }
}

// ── Event Card ─────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.rsvpInProgress,
    required this.onRsvp,
  });

  final Event event;
  final bool rsvpInProgress;
  final VoidCallback onRsvp;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final capacityPercent =
        e.capacity > 0 ? (e.rsvpCount / e.capacity).clamp(0.0, 1.0) : 0.0;
    final progressColor = capacityPercent > 0.8
        ? Colors.red
        : capacityPercent > 0.5
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + free/paid badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: e.isFree ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: e.isFree ? Colors.green : Colors.amber,
                    ),
                  ),
                  child: Text(
                    e.isFree ? 'FREE' : 'PAID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: e.isFree ? Colors.green : Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              e.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 10),

            // Date + location
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(e.date, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                const Text('·', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 6),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(e.timeStart, style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    e.location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Capacity bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.rsvpCount} / ${e.capacity} RSVPs',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: capacityPercent,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // RSVP button
                if (e.isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Full',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ElevatedButton(
                    onPressed: rsvpInProgress ? null : onRsvp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: rsvpInProgress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('RSVP'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
