import "package:flutter/material.dart";
import "screens/home_screen.dart";
import "screens/login_screen.dart";

// Global key for navigation from interceptors
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(const CampusConnectApp());

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // required for interceptor navigation
      title: "CampusConnect",
      debugShowCheckedModeBanner: false,
      initialRoute: "/home",
      routes: {
        "/home": (ctx) => const HomeScreen(),
        "/login": (ctx) => const LoginScreen(),
      },
    );
  }
}
