import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../admin/data/search_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/routes/app_routes.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScamLock'),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You will be signed out of ScamLock.'),
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
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Check before you transact.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.search);
                },
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by phone, G Number, or Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.lockPerson);
                  if (!mounted) return;
                  _loadMyLocks();
                },
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Lock a new person'),
              ),
              const SizedBox(height: 24),
              const Text(
                'People you have locked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadMyLocks,
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
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
                          child: Text('You haven\'t locked anyone yet.'),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                person['full_name'] as String? ??
                                    'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        lockCount > 1 ? Icons.warning_rounded : Icons.lock_outline,
                                        size: 16,
                                        color: lockCount > 1 ? Colors.red.shade700 : Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$lockCount ${lockCount == 1 ? 'firm' : 'firms'}',
                                        style: TextStyle(
                                          color: lockCount > 1 ? Colors.red.shade700 : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('+91 ${person['phone_no'] as String? ?? ''}',
                                      style: const TextStyle(color: Colors.black87)),
                                  if ((person['a_number'] as String? ?? '').isNotEmpty)
                                    Text('A Number: ${person['a_number']}'),
                                  if (dateLabel.isNotEmpty)
                                    Text(dateLabel, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openRecordDetail(lock),
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