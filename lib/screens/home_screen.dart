// lib/screens/home_screen.dart
// Main navigation shell with NavigationBar (Material 3).
// Hosts the four feature screens and manages the live notification badge.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Silently fetches the unread notification count for the badge.
  /// Fails silently — a missing badge is not a blocking error.
  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService().getNotifications();
      if (!mounted) return;
      setState(() {
        _unreadCount = result['unread_count'] as int? ?? 0;
      });
    } catch (_) {
      // Intentionally silent — badge defaults to 0.
    }
  }

  /// Called by NotificationsScreen each time the user reads a notification.
  void _onNotificationRead() {
    setState(() {
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    });
  }

  static const _titles = [
    'Announcements',
    'Events',
    'My Schedule',
    'Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    // Build screens here so _onNotificationRead closure is fresh.
    final screens = <Widget>[
      const AnnouncementsScreen(),
      const EventsScreen(),
      const ScheduleScreen(),
      NotificationsScreen(onNotificationRead: _onNotificationRead),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.school, size: 18, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh badge',
            onPressed: _loadUnreadCount,
          ),
          // Dev logout — clears stored token and returns to LoginScreen.
          // Will be replaced by a proper logout (POST /auth/logout) in Module 14.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout (Dev)',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      ),

      // IndexedStack keeps all screens alive; state is preserved on tab switch.
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // Refresh the unread badge count when the Notifications tab is opened.
          if (index == 3) _loadUnreadCount();
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.announcement_outlined),
            selectedIcon: Icon(Icons.announcement, color: Color(0xFF1565C0)),
            label: 'Announcements',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event, color: Color(0xFF1565C0)),
            label: 'Events',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon:
                Icon(Icons.calendar_view_week, color: Color(0xFF1565C0)),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child:
                  const Icon(Icons.notifications, color: Color(0xFF1565C0)),
            ),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
