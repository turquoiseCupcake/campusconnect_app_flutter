// lib/screens/register_screen.dart
// Registration screen implementation — Module 14, Section 5.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  Map<String, String?> _fieldErrors = {};
  String? _generalError;

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _emailController,
      _passwordController,
      _confirmController,
      _studentIdController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _fieldErrors = {};
      _generalError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        studentId: _studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } on DioException catch (e) {
      if (mounted) {
        if (e.response?.statusCode == 422) {
          final raw = e.response?.data['errors'] as Map? ?? {};
          setState(() => _fieldErrors = raw.map((k, v) =>
              MapEntry(k.toString(), (v as List).first.toString())));
        } else if (e.type == DioExceptionType.connectionError) {
          setState(() => _generalError = 'No internet connection.');
        } else {
          setState(() => _generalError = e.response?.data['message'] as String? ??
              'Registration failed.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    IconData? icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    String? serverError,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        errorText: serverError ?? _fieldErrors[label.toLowerCase().replaceAll(" ", "_")],
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_generalError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _generalError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(
                      ctrl: _nameController,
                      label: "Name",
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                      serverError: _fieldErrors["name"],
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                      serverError: _fieldErrors["email"],
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outlined,
                      obscure: _obscurePassword,
                      toggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                      serverError: _fieldErrors["password"],
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _confirmController,
                      label: "Confirm Password",
                      icon: Icons.lock_outlined,
                      obscure: _obscureConfirm,
                      toggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                      serverError: _fieldErrors["password_confirmation"],
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _studentIdController,
                      label: "Student ID (optional)",
                      icon: Icons.badge_outlined,
                      serverError: _fieldErrors["student_id"],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Log In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
