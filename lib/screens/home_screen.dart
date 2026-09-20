// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'announcements_screen.dart';
import 'events_screen.dart';
import 'schedule_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService().getNotifications();
      setState(() => _unreadCount = result["unread_count"] as int);
    } catch (_) {} // silently fail — badge just shows 0
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const AnnouncementsScreen(),
      const EventsScreen(),
      const ScheduleScreen(),
      NotificationsScreen(
        onNotificationRead: () {
          setState(() => _unreadCount = (_unreadCount - 1).clamp(0, 999));
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 3) _loadUnreadCount();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: "Announcements",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: "Events",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text("$_unreadCount"),
              child: const Icon(Icons.notifications),
            ),
            label: "Notifications",
          ),
        ],
      ),
    );
  }
}
