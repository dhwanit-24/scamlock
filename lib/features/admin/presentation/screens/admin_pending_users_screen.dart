import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class AdminPendingUsersScreen extends StatefulWidget {
  const AdminPendingUsersScreen({super.key});

  @override
  State<AdminPendingUsersScreen> createState() =>
      _AdminPendingUsersScreenState();
}

class _AdminPendingUsersScreenState extends State<AdminPendingUsersScreen> {
  final _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action successful.')),
      );
      await _loadPendingUsers();
    } catch (error) {
      debugPrint('$action error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingUsers,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
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
                child: Text('No pending approvals right now.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['firm_name'] as String? ?? 'Unknown Firm',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user['full_name'] as String? ?? '',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              '+91 ${user['phone'] as String? ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            if (user['firm_location'] != null &&
                (user['firm_location'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user['firm_location'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}