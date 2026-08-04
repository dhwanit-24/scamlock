import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/auth_repository.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with WidgetsBindingObserver {
  final _authRepository = AuthRepository();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToStatusChanges();
  }

  void _subscribeToStatusChanges() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = Supabase.instance.client
        .channel('profile-status-$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: (payload) {
        final status = payload.newRecord['account_status'] as String?;
        final role = payload.newRecord['app_role'] as String?;
        _handleStatus(status, role);
      },
    )
        .subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckStatus();
    }
  }

  Future<void> _recheckStatus() async {
    try {
      final profile = await _authRepository.getCurrentProfile();
      if (profile == null) return;
      _handleStatus(
        profile['account_status'] as String?,
        profile['app_role'] as String?,
      );
    } catch (error) {
      debugPrint('Pending approval recheck error: $error');
    }
  }

  void _handleStatus(String? status, String? role) {
    if (!mounted || status == null) return;

    if (status == 'active') {
      Navigator.of(context).pushReplacementNamed(
        role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.home,
      );
    } else if (status == 'suspended' || status == 'rejected') {
      _signOutAndReturnToLogin();
    }
    // status == 'pending' -> stay right here, nothing to do
  }

  Future<void> _signOutAndReturnToLogin() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 72,
                  color: Color(0xFFB42318),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Request submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your firm is waiting for administrator approval. '
                      'You will be able to use ScamLock after approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}