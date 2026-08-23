import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialogs.dart';

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
  bool _obscurePassword = true;

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

  Future<void> _showMessage(String message) async {
    if (!mounted) return;

    await AppDialogs.showError(
      context,
      title: 'Unable to sign in',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),

                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              color: AppColors.signalRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 44,
                              color: AppColors.canvas,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        const Text(
                          'ScamLock',
                          textAlign: TextAlign.center,
                          style: AppTypography.headline,
                        ),

                        const SizedBox(height: AppSpacing.xxs),

                        const Text(
                          'Check before you transact.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body,
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_isSubmitting,
                          style: AppTypography.body,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: AppColors.ink,
                            ),
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

                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          enabled: !_isSubmitting,
                          style: AppTypography.body,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.ink,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.ink,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        FilledButton(
                          onPressed: _isSubmitting ? null : _handleSignIn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.canvas,
                              ),
                            )
                                : const Text('Sign in'),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

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
          },
        ),
      ),
    );
  }
}