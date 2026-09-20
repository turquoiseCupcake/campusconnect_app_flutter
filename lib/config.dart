// lib/config.dart
// Environment-based configuration as defined in Module 13, Section 10.

class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
