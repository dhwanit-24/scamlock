import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authRepository.signIn(
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      final profile = await _authRepository.getCurrentProfile();
      if (!mounted) return;

      if (profile == null) {
        _showMessage('Profile not found. Please contact support.');
        return;
      }

      final status = profile['account_status'] as String;
      final role = profile['app_role'] as String;

      if (status == 'pending') {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.pendingApproval,
        );
      } else if (status == 'active') {
        if (role == 'admin') {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.adminDashboard,
          );
        } else {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.home,
          );
        }
      } else if (status == 'suspended') {
        _showMessage('Your access is suspended. Contact administrator.');
      } else if (status == 'rejected') {
        _showMessage('Your account was rejected.');
      } else {
        _showMessage('Unknown account status.');
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      debugPrint('Error: $error');
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                const Icon(
                  Icons.shield_outlined,
                  size: 72,
                  color: Color(0xFFB42318),
                ),

                const SizedBox(height: 20),

                const Text(
                  'ScamLock',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Check before you transact.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 48),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final digitsOnly =
                        (value ?? '').replaceAll(RegExp(r'\D'), '');

                    if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) {
                      return 'Enter a valid 10-digit phone number.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSignIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign in'),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.requestAccess,
                    );
                  },
                  child: const Text('New firm? Request access'),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}