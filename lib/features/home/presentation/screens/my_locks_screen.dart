import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

class MyLocksScreen extends StatefulWidget {
  const MyLocksScreen({super.key});

  @override
  State<MyLocksScreen> createState() => _MyLocksScreenState();
}

class _MyLocksScreenState extends State<MyLocksScreen>
    with WidgetsBindingObserver {
  final _searchRepository = SearchRepository();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMyLocks();
    }
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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: AppSpacing.lg,
        title: const Text('My Locks', style: AppTypography.cardTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            0,
          ),
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
                    final isFlagged = lockCount > 0;

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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                            padding: const EdgeInsets
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
                                              mainAxisSize: MainAxisSize.min,
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
                                                const SizedBox(width: 4),
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
                                      const SizedBox(height: AppSpacing.xs),
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
                                            style: AppTypography.bodySm,
                                          ),
                                        ),
                                      if (dateLabel.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets
                                              .only(top: AppSpacing.xs),
                                          child: Text(
                                            dateLabel,
                                            style: AppTypography.caption,
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
      ),
    );
  }
}
