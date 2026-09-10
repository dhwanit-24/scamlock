import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../support/presentation/widgets/support_fab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authRepository.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load profile error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load profile.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Sign out?', style: AppTypography.cardTitle),
        content: const Text(
          'You will be signed out of ScamLock.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return ;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: const SupportFab(),
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: AppSpacing.lg,
        title: const Text('Profile', style: AppTypography.cardTitle),
        actions: [
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout, color: AppColors.ink),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                );
              }

              if (_errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.signalRed,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (_profile == null) {
                return const Center(
                  child: Text('No profile data found.', style: AppTypography.body),
                );
              }

              final fullName = _profile!['full_name'] as String? ?? '';
              final firmName = _profile!['firm_name'] as String? ?? '';
              final phone = _profile!['phone'] as String? ?? '';
              final email = _profile!['email'] as String? ?? '';
              final firmLocation = _profile!['firm_location'] as String? ?? '';

              return ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  _ProfileRow(label: 'Full Name', value: fullName),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileRow(label: 'Firm Name', value: firmName),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileRow(label: 'Phone', value: '+91 $phone'),
                  const SizedBox(height: AppSpacing.md),
                  if (email.isNotEmpty) ...[
                    _ProfileRow(label: 'Email', value: email),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ProfileRow(label: 'Firm Location', value: firmLocation),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}
