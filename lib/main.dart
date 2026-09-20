// lib/main.dart
// Entry point for the CampusConnect Flutter app — Module 13.
//
// navigatorKey is declared here (not in a service file) so that:
//   - _AuthInterceptor in api_service.dart can import it with `show navigatorKey`
//   - It lives at the top level and is available before any Widget is built.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Global navigator key — required by [_AuthInterceptor] to redirect
/// to /login when the API returns a 401 (expired / revoked token).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const CampusConnectApp());
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // required for interceptor-triggered navigation
      title: 'CampusConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // Determine the initial route based on whether a token is already stored.
      // FutureBuilder is used so the decision is async-safe.
      home: const _SplashRouter(),
      routes: {
        '/home':  (ctx) => const HomeScreen(),
        '/login': (ctx) => const LoginScreen(),
      },
    );
  }
}

/// Checks SharedPreferences for a stored auth_token and redirects accordingly.
/// Shows a branded splash while deciding which route to go to.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Small delay so the splash is visible
    await Future.delayed(const Duration(milliseconds: 800));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    // If a token exists, go straight to HomeScreen; otherwise show LoginScreen.
    Navigator.pushReplacementNamed(context, token != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.school, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'CampusConnect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Module 13 — HTTP + Dio',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }
}
