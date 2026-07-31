import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../admin/data/search_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchRepository = SearchRepository();
  List<Map<String, dynamic>> _lockedPeople = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyLocks();
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
        'lockCount': 0,
        'phoneNo': person['phone_no'] as String? ?? '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScamLock'),
        actions: [
          IconButton(
            onPressed: () async {
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
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.lockPerson);
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      '+91 ${person['phone_no'] as String? ?? ''}'),
                                  if ((person['a_number'] as String? ?? '')
                                      .isNotEmpty)
                                    Text('A Number: ${person['a_number']}'),
                                  if (dateLabel.isNotEmpty)
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
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