import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/human_verification_exception.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  bool _isLoading = false;
  bool _showTotp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _usernameController.text.trim(),
          _passwordController.text,
          _showTotp ? _totpController.text.trim() : null,
        );
      } on HumanVerificationException catch (e) {
        await _handleHumanVerification(e);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleHumanVerification(HumanVerificationException e) async {
    final tokenController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('human verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('complete the captcha in your browser, '
                'then paste the verification token below.'),
            const SizedBox(height: 12),
            CustomButton(
              text: 'open browser',
              onPressed: () async {
                final uri = Uri.tryParse(e.webUrl);
                if (uri != null) {
                  try {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'verification token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('cancel'),
          ),
          CustomButton(
            text: 'submit',
            onPressed: () => Navigator.of(ctx).pop(tokenController.text.trim()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .loginWithHumanVerification(
          e.username,
          _passwordController.text,
          result,
          e.clientEphemeral,
          e.clientProof,
          e.srpSession,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo or title
                  Text(
                    'vpn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _usernameController,
                    label: 'username or email',
                    icon: Icons.person_outline,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'enter your username' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'enter your password' : null,
                  ),
                  const SizedBox(height: 16),
                  // TOTP field (conditionally shown)
                  if (_showTotp)
                    CustomTextField(
                      controller: _totpController,
                      label: 'two-factor code',
                      icon: Icons.qr_code,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'enter 2fa code' : null,
                    ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: _isLoading ? 'connecting...' : 'login',
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Forgot password?
                    },
                    child: const Text('forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}