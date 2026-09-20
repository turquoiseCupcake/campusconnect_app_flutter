// lib/screens/login_screen.dart
// Module 13 placeholder screen — real auth is implemented in Module 14.
// Allows manual token storage via SharedPreferences to authenticate requests.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();

  Future<void> _saveToken() async {
    final token = _controller.text.trim();
    if (token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CampusConnect — Login")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              "Module 13 Placeholder Login",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter a Sanctum token from your Laravel API to authenticate requests.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Sanctum Bearer Token",
                hintText: "Paste token here",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveToken,
              child: const Text("Save Token & Enter App"),
            ),
          ],
        ),
      ),
    );
  }
}
