import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _validateSession();
    }
  }

  Future<bool> _validateSession() async {
    try {
      final profile = await _authRepository.getCurrentProfile();
      if (profile == null) {
        await _signOutAndReturnToLogin(
          'Session expired. Please sign in again.',
        );
        return false;
      }
      final status = profile['account_status'] as String? ?? '';
      if (status != 'active') {
        await _signOutAndReturnToLogin(_statusMessage(status));
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('Session validation error: $error');
      return true;
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'suspended':
        return 'Your access is suspended. Contact administrator.';
      case 'rejected':
        return 'Your account was rejected.';
      case 'pending':
        return 'Your account is pending approval.';
      default:
        return 'Your session is no longer valid. Please sign in again.';
    }
  }

  Future<void> _signOutAndReturnToLogin(String message) async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'ScamLock',
              style: AppTypography.cardTitle,
            ),
          ],
        ),
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

      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: AppSpacing.lg,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(
              Icons.logout,
              color: AppColors.ink,
            ),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // ScamLock brand mark
                      Column(
                        children: [
                          SizedBox(
                            height: constraints.maxHeight * 0.10,
                          ),

                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: constraints.maxWidth * 0.50,
                                color: AppColors.ink,
                              ),
                              Icon(
                                Icons.lock,
                                size: constraints.maxWidth * 0.09,
                                color: AppColors.signalRed,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          Text(
                            'ScamLock',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 29,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Lock a new person
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context)
                                .pushNamed(AppRoutes.lockPerson);
                          },
                          icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                          ),
                          label: const Text('Lock a new person'),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Search
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.search);
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            style: AppTypography.body,
                            decoration: const InputDecoration(
                              labelText:
                              'Search by phone, G Number, or Name',
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Tagline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 15,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Check before you transact.',
                            style: AppTypography.subhead.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: AppColors.canvas,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelBehavior:
        NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.lock_outline,
              color: AppColors.ink,
            ),
            selectedIcon: Icon(
              Icons.lock_outline,
              color: AppColors.ink,
            ),
            label: 'My Locks',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: AppColors.ink,
            ),
            selectedIcon: Icon(
              Icons.person_outline,
              color: AppColors.ink,
            ),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushNamed(
              AppRoutes.myLocks,
            );
          } else if (index == 1) {
            Navigator.of(context).pushNamed(
              AppRoutes.profile,
            );
          }
        },
      ),
    );
  }
}
