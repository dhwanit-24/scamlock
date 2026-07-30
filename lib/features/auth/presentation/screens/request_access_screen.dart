import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../../../../core/routes/app_routes.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _fullNameController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _firmNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authRepository.requestAccess(
        fullName: _fullNameController.text,
        firmName: _firmNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        firmLocation: _locationController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.pendingApproval,
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Something went wrong. Please check your connection and try again.',
      );
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

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request access')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Join ScamLock',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your firm must be approved by an administrator before access is granted.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputStyle(
                  label: 'Your name',
                  icon: Icons.person_outline,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firmNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputStyle(
                  label: 'Firm name',
                  icon: Icons.business_outlined,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputStyle(
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputStyle(
                  label: 'Email address (optional)',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputStyle(
                  label: 'Firm location',
                  icon: Icons.location_on_outlined,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputStyle(
                  label: 'Create password',
                  icon: Icons.lock_outline,
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Submit request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}