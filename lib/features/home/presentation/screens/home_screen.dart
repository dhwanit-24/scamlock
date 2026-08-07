import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../admin/data/search_repository.dart';
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
  final _searchRepository = SearchRepository();
  final _authRepository = AuthRepository();
  List<Map<String, dynamic>> _lockedPeople = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyLocks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (await _validateSession()) {
        _loadMyLocks();
      }
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

  Future<void> _loadMyLocks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final people = await _searchRepository.getMyLockedPeople();
      if (!mounted) return;
      setState(() {
        _lockedPeople = people;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load my locks error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load your locks. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  void _openRecordDetail(Map<String, dynamic> lock) {
    final person = lock['person'] as Map<String, dynamic>?;
    if (person == null) return;

    Navigator.of(context).pushNamed(
      AppRoutes.recordDetail,
      arguments: {
        'personId': person['id'] as String,
        'person': person,
      },
    );
  }

  int _totalLockCount(Map<String, dynamic> person) {
    final locks = person['locks'];
    if (locks is List) {
      final first = locks.isNotEmpty ? locks.first : null;
      if (first is Map) {
        final count = first['count'];
        if (count is int) return count;
        if (count is String) return int.tryParse(count) ?? 0;
      }
      return 0;
    }
    if (locks is Map) {
      final count = locks['count'];
      if (count is int) return count;
      if (count is String) return int.tryParse(count) ?? 0;
    }
    return 0;
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
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
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
        title: const Text('ScamLock', style: AppTypography.cardTitle),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Check before you transact.',
                textAlign: TextAlign.center,
                style: AppTypography.subhead,
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.search);
                },
                child: AbsorbPointer(
                  child: TextField(
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      labelText: 'Search by phone, G Number, or Name',
                      prefixIcon: Icon(Icons.search, color: AppColors.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.lockPerson);
                  if (!mounted) return;
                  _loadMyLocks();
                },
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Lock a new person'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'People you have locked',
                  style: AppTypography.eyebrow,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.ink,
                  onRefresh: _loadMyLocks,
                  child: Builder(
                    builder: (context) {
                      if (_isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.ink,
                          ),
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
                                  onPressed: _loadMyLocks,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (_lockedPeople.isEmpty) {
                        return const Center(
                          child: Text(
                            'You haven\'t locked anyone yet.',
                            style: AppTypography.body,
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        itemCount: _lockedPeople.length,
                        itemBuilder: (context, index) {
                          final lock = _lockedPeople[index];
                          final person =
                          lock['person'] as Map<String, dynamic>?;
                          if (person == null) return const SizedBox.shrink();

                          final lockedOn = lock['locked_on'] as String? ?? '';
                          final dateLabel = lockedOn.isNotEmpty
                              ? 'Locked: ${lockedOn.split('T').first}'
                              : '';
                          final lockCount = _totalLockCount(person);
                          final isFlagged = lockCount > 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius:
                              BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius:
                              BorderRadius.circular(AppRadius.md),
                              child: InkWell(
                                borderRadius:
                                BorderRadius.circular(AppRadius.md),
                                onTap: () => _openRecordDetail(lock),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    person['full_name']
                                                    as String? ??
                                                        'Unknown',
                                                    style: AppTypography
                                                        .cardTitle,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                    horizontal: AppSpacing.xs,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isFlagged
                                                        ? AppColors.blockBlush
                                                        : AppColors.blockLime,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.pill),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isFlagged
                                                            ? Icons
                                                            .warning_rounded
                                                            : Icons
                                                            .lock_outline,
                                                        size: 14,
                                                        color: isFlagged
                                                            ? AppColors
                                                            .signalRed
                                                            : AppColors.ink,
                                                      ),
                                                      const SizedBox(
                                                          width: 4),
                                                      Text(
                                                        '$lockCount ${lockCount == 1 ? 'firm' : 'firms'}',
                                                        style: AppTypography
                                                            .bodySm
                                                            .copyWith(
                                                          color: isFlagged
                                                              ? AppColors
                                                              .signalRed
                                                              : AppColors.ink,
                                                          fontWeight:
                                                          FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                            Text(
                                              '+91 ${person['phone_no'] as String? ?? ''}',
                                              style: AppTypography.body,
                                            ),
                                            if ((person['a_number']
                                            as String? ??
                                                '')
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets
                                                    .only(top: 2),
                                                child: Text(
                                                  'A Number: ${person['a_number']}',
                                                  style:
                                                  AppTypography.bodySm,
                                                ),
                                              ),
                                            if (dateLabel.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets
                                                    .only(top: AppSpacing.xs),
                                                child: Text(
                                                  dateLabel,
                                                  style:
                                                  AppTypography.caption,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.ink,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}