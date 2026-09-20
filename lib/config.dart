/// Application-level configuration.
///
/// Base URL selection by target:
///   Android emulator  → http://10.0.2.2:8000/api/v1  (default)
///   iOS simulator     → http://localhost:8000/api/v1
///   Physical device   → http://192.168.x.x:8000/api/v1
///   Production        → https://api.campusconnect.edu/api/v1
///
/// Override at run time (no code change needed):
///   flutter run --dart-define=BASE_URL=http://192.168.1.100:8000/api/v1
///
/// WSL2 note: `php artisan serve` inside WSL2 is reachable from the
/// Android emulator via 10.0.2.2 because Windows forwards that port.
/// If it fails, run `php artisan serve --host=0.0.0.0` inside WSL2 and
/// find your WSL2 IP with `ip addr show eth0` — use that IP here instead.
class AppConfig {
  AppConfig._(); // prevent instantiation

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
