import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialogs.dart';

class AdminPendingUsersScreen extends StatefulWidget {
  const AdminPendingUsersScreen({super.key});

  @override
  State<AdminPendingUsersScreen> createState() =>
      _AdminPendingUsersScreenState();
}

class _AdminPendingUsersScreenState extends State<AdminPendingUsersScreen>
    with WidgetsBindingObserver {
  final _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPendingUsers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPendingUsers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _adminRepository.getPendingUsers();
      if (!mounted) return;
      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load pending users error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load users. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAction({
    required String userId,
    required String userName,
    required String action,
    required String status,
    required String actionType,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action $userName?'),
        content: Text(
          action == 'Approve'
              ? 'This firm will get full access to ScamLock.'
              : 'This firm will not be able to access ScamLock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminRepository.updateUserStatus(
        userId: userId,
        status: status,
        actionType: actionType,
      );

      if (!mounted) return;
      await AppDialogs.showSuccess(
        context,
        title: '$action successful',
        message: action == 'Approve'
            ? 'This firm now has full access to ScamLock.'
            : 'This firm has been rejected and will not have access to ScamLock.',
      );
      await _loadPendingUsers();
    } catch (error) {
      debugPrint('$action error: $error');
      if (!mounted) return;
      await AppDialogs.showError(
        context,
        title: 'Action failed',
        message: 'Something went wrong. Please try again.',
      );
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
        title: const Text(
          'Pending Approvals',
          style: AppTypography.cardTitle,
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: _loadPendingUsers,
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
                        onPressed: _loadPendingUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_pendingUsers.isEmpty) {
              return const Center(
                child: Text(
                  'No pending approvals right now.',
                  style: AppTypography.body,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _pendingUsers.length,
              itemBuilder: (context, index) {
                final user = _pendingUsers[index];

                return _PendingUserCard(
                  user: user,
                  onApprove: () => _confirmAction(
                    userId: user['id'] as String,
                    userName: user['firm_name'] as String,
                    action: 'Approve',
                    status: 'active',
                    actionType: 'approved',
                  ),
                  onReject: () => _confirmAction(
                    userId: user['id'] as String,
                    userName: user['firm_name'] as String,
                    action: 'Reject',
                    status: 'rejected',
                    actionType: 'rejected',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  const _PendingUserCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.blockCream,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user['firm_name'] as String? ?? 'Unknown Firm',
            style: AppTypography.cardTitle,
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            user['full_name'] as String? ?? '',
            style: AppTypography.bodySm,
          ),

          const SizedBox(height: 2),

          Text(
            '+91 ${user['phone'] as String? ?? ''}',
            style: AppTypography.bodySm,
          ),

          if (user['firm_location'] != null &&
              (user['firm_location'] as String).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              user['firm_location'] as String,
              style: AppTypography.bodySm,
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(
                      color: AppColors.hairline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadius.pill,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}