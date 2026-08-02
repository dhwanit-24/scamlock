import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen>
    with WidgetsBindingObserver {
  final _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _processingUserId;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUsers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _adminRepository.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      _applyFilter();
    } catch (error) {
      debugPrint('Load users error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load users. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      setState(() {
        _filteredUsers = List.from(_users);
      });
    } else {
      setState(() {
        _filteredUsers = _users
            .where((u) => u['account_status'] == _selectedFilter)
            .toList();
      });
    }
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    final labelWithCount = '$label ($count)';

    return FilterChip(
      label: Text(labelWithCount),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter();
      },
    );
  }

  Future<void> _toggleStatus({
    required String userId,
    required String currentStatus,
    required String userName,
  }) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    final actionType = currentStatus == 'active' ? 'suspended' : 'activated';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
         title: Text('${actionType == 'suspended' ? 'Suspend' : 'Activate'} $userName?'),
        content: Text(
           actionType == 'suspended'
              ? 'This firm will lose search and lock access. They can still view their own locked records.'
              : 'This firm will regain full access to ScamLock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionType == 'suspended' ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _processingUserId = userId;
    });

    try {
      await _adminRepository.updateUserStatus(
        userId: userId,
        status: newStatus,
        actionType: actionType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$actionType successful.')),
      );
      try
      { await _loadUsers(); } catch (_) { }
    } catch (error) {
      debugPrint('$actionType error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _users.where((u) => u['account_status'] == 'pending').length;
    final activeCount =
        _users.where((u) => u['account_status'] == 'active').length;
    final suspendedCount =
        _users.where((u) => u['account_status'] == 'suspended').length;
    final rejectedCount =
        _users.where((u) => u['account_status'] == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
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
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', _users.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Pending', 'pending', pendingCount),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Active', 'active', activeCount),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Suspended', 'suspended', suspendedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Rejected', 'rejected', rejectedCount),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(
                          child: Text('No users match this filter.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final isProcessing =
                                _processingUserId == user['id'];
                            final status = user['account_status']
                                    as String? ??
                                'pending';
                            final canToggle = status == 'active' ||
                                status == 'suspended';

                            return _UserCard(
                              firmName:
                                  user['firm_name'] as String? ??
                                      'Unknown Firm',
                              fullName:
                                  user['full_name'] as String? ??
                                      '',
                              phone: user['phone'] as String? ?? '',
                              location: user['firm_location']
                                      as String? ??
                                  '',
                              status: status,
                              role:
                                  user['app_role'] as String? ??
                                      'member',
                              createdAt:
                                  user['created_at'] as String? ??
                                      '',
                              isProcessing: isProcessing,
                              selectedFilter: _selectedFilter,
                              canToggle: canToggle,
                              onToggle: canToggle
                                  ? () => _toggleStatus(
                                        userId: user['id']
                                            as String,
                                        currentStatus: status,
                                        userName: user['firm_name']
                                            as String,
                                      )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.firmName,
    required this.fullName,
    required this.phone,
    required this.location,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.isProcessing,
    required this.selectedFilter,
    required this.canToggle,
    required this.onToggle,
  });

  final String firmName;
  final String fullName;
  final String phone;
  final String location;
  final String status;
  final String role;
  final String createdAt;
  final bool isProcessing;
  final bool canToggle;
  final String selectedFilter;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final statusLabel = status.toUpperCase();
    final dateLabel = createdAt.isNotEmpty
        ? createdAt.split('T').first
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    firmName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fullName,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              '+91 $phone',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Joined: $dateLabel',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
            if (role == 'admin') ...[
              const SizedBox(height: 4),
              const Text(
                'Role: Admin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
            if (selectedFilter == 'active' && status == 'active') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isProcessing
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onToggle,
                        icon: const Icon(Icons.pause, size: 18),
                        label: const Text('Suspend'),
                      ),
              ),
            ] else if (selectedFilter == 'suspended' && status == 'suspended') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isProcessing
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onToggle,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Activate'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}