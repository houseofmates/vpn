import 'package:vpn/providers/server_provider.dart';
import 'package:vpn/providers/connection_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vpn/screens/login_screen.dart';
import 'package:vpn/screens/home_screen.dart';
import 'package:vpn/providers/auth_provider.dart';
import 'package:vpn/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
      ],
      child: MaterialApp(
        title: 'VPN',
        theme: theme(),
        home: const AuthChecker(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Try to refresh token or check if we have a user
      final user = authProvider.user;
      if (user != null && user.AccessToken.isNotEmpty) {
        // We have a user, but we should verify the token is still valid
        // For simplicity, we'll just go to home screen.
        _isAuthenticated = true;
      } else {
        // Try to refresh token
        await authProvider.refreshToken();
        if (authProvider.user != null) {
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      // If any error, we are not authenticated
      _isAuthenticated = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF6B012),
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}