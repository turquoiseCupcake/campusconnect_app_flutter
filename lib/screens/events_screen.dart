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
      setState(() {
        _events = data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data["message"] ?? "Could not load events.";
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
        SnackBar(content: Text('RSVP confirmed for ${event.title}!')),
      );
      _loadEvents(); // refresh to update rsvp_count
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data["message"] ?? "RSVP failed.")),
      );
    } finally {
      if (mounted) {
        setState(() => _rsvpInProgress.remove(event.id));
      }
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
              TextButton(onPressed: _loadEvents, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _events.isEmpty
            ? const Center(child: Text('No upcoming events.'))
            : ListView.builder(
                itemCount: _events.length,
                itemBuilder: (ctx, i) {
                  final e = _events[i];
                  final inProgress = _rsvpInProgress.contains(e.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(e.date),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  e.location,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text("${e.rsvpCount}/${e.capacity} RSVPs"),
                              const Spacer(),
                              if (e.isFull)
                                const Chip(label: Text('Full'))
                              else
                                ElevatedButton(
                                  onPressed: inProgress ? null : () => _rsvp(e),
                                  child: inProgress
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text("RSVP"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
