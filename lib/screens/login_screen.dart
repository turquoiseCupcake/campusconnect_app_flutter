// lib/screens/login_screen.dart
// Module 13 placeholder — real authentication (POST /auth/login) is implemented in Module 14.
// This screen lets you paste a Sanctum token from your Laravel backend for dev/testing.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController();
  bool _saving = false;

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a valid Sanctum token.')),
      );
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),

                Text(
                  'CampusConnect',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Module 13 — Dev Mode',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️  Paste your Sanctum token below to test the API.\n'
                    'Real login (POST /auth/login) is implemented in Module 14.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),

                // Token field
                TextField(
                  controller: _tokenController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: 'Sanctum Token',
                    labelStyle: const TextStyle(color: Colors.white54),
                    hintText: 'Paste the token from POST /api/v1/auth/login',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF1565C0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A2A3A),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      // Quick helper: get token via WSL curl (just shows instructions)
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Get a token from WSL'),
                          content: const SelectableText(
                            'In your WSL terminal:\n\n'
                            'cd ~/campusconnect-api\n'
                            'php artisan serve --host=0.0.0.0\n\n'
                            'Then in another terminal:\n'
                            'curl -s -X POST http://localhost:8000/api/v1/auth/login \\\n'
                            '  -H "Content-Type: application/json" \\\n'
                            '  -d \'{"email":"your@email.com","password":"password"}\'\n\n'
                            'Copy the "token" value from the response.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('How to get a token'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveToken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Token & Enter App',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
