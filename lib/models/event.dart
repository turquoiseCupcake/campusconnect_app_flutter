// lib/models/event.dart
// Type-safe model for the GET /api/v1/events response items.

class Event {
  final int id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String timeStart;
  final String category;
  final int capacity;
  final int rsvpCount;
  final int seatsAvailable;
  final bool isFull;
  final bool isFree;
  final Map<String, dynamic>? organizer;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.timeStart,
    required this.category,
    required this.capacity,
    required this.rsvpCount,
    required this.seatsAvailable,
    required this.isFull,
    required this.isFree,
    this.organizer,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id:             json['id'] as int,
        title:          json['title'] as String,
        description:    json['description'] as String,
        location:       json['location'] as String,
        date:           json['date'] as String,
        timeStart:      json['time_start'] as String,
        category:       json['category'] as String,
        capacity:       json['capacity'] as int,
        rsvpCount:      json['rsvp_count'] as int? ?? 0,
        seatsAvailable: json['seats_available'] as int? ?? 0,
        isFull:         json['is_full'] as bool? ?? false,
        isFree:         json['is_free'] as bool? ?? true,
        organizer:      json['organizer'] as Map<String, dynamic>?,
      );
}
