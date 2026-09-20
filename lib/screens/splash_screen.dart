// lib/screens/splash_screen.dart
// Session restore on startup — Module 14, Section 3.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // No token → go straight to login
    if (token == null) {
      _goTo('/login');
      return;
    }

    // Token exists → verify it with /me
    try {
      await AuthService().getMe(); // updates "user_data" cache on success
      _goTo('/home');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token is expired/revoked — clear it and go to login
        await prefs.remove('auth_token');
        _goTo('/login');
      } else {
        // Network error — show retry
        if (mounted) setState(() => _error = 'Cannot connect to server.');
      }
    }
  }

  void _goTo(String route) {
    if (mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo / branding
            const Icon(Icons.school, size: 80, color: Color(0xFF1565C0)),
            const SizedBox(height: 16),
            const Text(
              'CampusConnect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 48),
            if (_error == null)
              const CircularProgressIndicator()
            else ...[
              Text(_error!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _error = null);
                  _checkAuthStatus();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
