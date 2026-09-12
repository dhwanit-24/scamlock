import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../update/data/update_repository.dart';
import '../../../update/domain/version_compare.dart';
import '../../../update/presentation/widgets/update_dialog.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/auth_repository.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await UpdateRepository().getLatestVersionInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      if (info != null &&
          isNewerVersion(packageInfo.version, info.latestVersion) &&
          mounted) {
        await showUpdateDialog(context, info);
      }
    } catch (error) {
      debugPrint('Update check error: $error');
    }

    if (!mounted) return;
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      _goTo(AppRoutes.login);
      return;
    }

    try {
      final profile = await _authRepository.getCurrentProfile();
      if (!mounted) return;

      if (profile == null) {
        await Supabase.instance.client.auth.signOut();
        _goTo(AppRoutes.login);
        return;
      }

      final status = profile['account_status'] as String? ?? '';
      final role = profile['app_role'] as String? ?? '';

      if (status == 'pending') {
        _goTo(AppRoutes.pendingApproval);
      } else if (status == 'active') {
        _goTo(role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.home);
      } else {
        await Supabase.instance.client.auth.signOut();
        _goTo(AppRoutes.login);
      }
    } catch (error) {
      debugPrint('Auth gate session check error: $error');
      if (!mounted) return;
      _goTo(AppRoutes.login);
    }
  }

  void _goTo(String route) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}