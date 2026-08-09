import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import '../../../../core/theme/app_theme.dart';

String _resolveName(Map<String, dynamic> entry, String key) {
  final map = entry[key] as Map<String, dynamic>?;
  if (map == null) return 'Unknown';
  final firmName = map['firm_name'] as String?;
  if (firmName != null && firmName.isNotEmpty) return firmName;
  final fullName = map['full_name'] as String?;
  return fullName?.isNotEmpty == true ? fullName! : 'Unknown';
}

class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen>
    with WidgetsBindingObserver {
  final _searchRepository = SearchRepository();
  Map<String, dynamic>? _person;
  List<Map<String, dynamic>> _locks = [];
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _myLock;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_person != null) return;

    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>?;
    if (args != null) {
      final person = args['person'] as Map<String, dynamic>?;
      if (person != null) {
        _person = person;
      }
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>?;
    if (args == null) return;

    final personId = args['personId'] as String?;
    if (personId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locks = await _searchRepository.getPersonLocks(personId);
      final events = await _searchRepository.getPersonLockEvents(personId);
      final myLock = await _searchRepository.findMyLock(personId);

      if (!mounted) return;
      setState(() {
        _locks = locks;
        _events = events;
        _myLock = myLock;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load record detail error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load details. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMyLock() async {
    final personId = _person?['id'] as String?;
    if (personId == null) return;

    final hasActiveLock = _myLock != null && _myLock!['status'] == 'locked';
    final newStatus = hasActiveLock ? 'unlocked' : 'locked';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          hasActiveLock ? 'Unlock this person?' : 'Lock this person?',
          style: AppTypography.cardTitle,
        ),
        content: Text(
          hasActiveLock
              ? 'Your firm\'s lock will be removed. Other firms\' locks remain.'
              : 'Your firm will flag this person.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(hasActiveLock ? 'Unlock' : 'Lock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (_myLock == null) {
        await _searchRepository.createPersonLock(personId);
      } else {
        await _searchRepository.updateMyLockStatus(personId, newStatus);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hasActiveLock ? 'Unlocked.' : 'Locked.')),
      );
      _loadData();
    } catch (error) {
      debugPrint('Toggle lock error: $error');
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
    final hasActiveLock = _myLock != null && _myLock!['status'] == 'locked';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text('Record Detail', style: AppTypography.cardTitle),
        actions: [
          if (_person != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilledButton.icon(
                onPressed: _toggleMyLock,
                style: hasActiveLock
                    ? FilledButton.styleFrom(
                  backgroundColor: AppColors.signalRed,
                  foregroundColor: AppColors.canvas,
                  textStyle: AppTypography.button,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                )
                    : null,
                icon: Icon(
                  hasActiveLock ? Icons.lock_open : Icons.lock,
                  size: 18,
                ),
                label: Text(
                  hasActiveLock ? 'Unlock' : 'Lock',
                ),
              ),
            )
        ],
      ),
      body: _person == null && _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
          : RefreshIndicator(
        color: AppColors.ink,
        onRefresh: _loadData,
        child: Builder(
          builder: (context) {
            if (_isLoading && _person == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              );
            }

            if (_errorMessage != null && _person == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
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
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_person != null) _PersonInfoCard(person: _person!),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.ink),
                    ),
                  )
                else ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'LOCKED BY',
                    style: AppTypography.eyebrow,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_locks.isEmpty)
                    const Text('No locks yet.', style: AppTypography.body)
                  else
                    ..._locks.map(
                          (lock) => _LockCard(lock: lock),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'LOCK HISTORY',
                    style: AppTypography.eyebrow,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_events.isEmpty)
                    const Text('No history yet.', style: AppTypography.body)
                  else
                    ..._events.map(
                          (event) => _EventCard(event: event),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PersonInfoCard extends StatelessWidget {
  const _PersonInfoCard({required this.person});

  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person['full_name'] as String? ?? 'Unknown',
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '+91 ${person['phone_no'] as String? ?? ''}',
            style: AppTypography.body,
          ),
          if (person['g_number'] != null &&
              (person['g_number'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'G Number: ${person['g_number']}',
                style: AppTypography.bodySm,
              ),
            ),
          if (person['a_number'] != null &&
              (person['a_number'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'A Number: ${person['a_number']}',
                style: AppTypography.bodySm,
              ),
            ),
          if ((person['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Description: ${person['description']}',
              style: AppTypography.bodySm,
            ),
          ],
        ],
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.lock});

  final Map<String, dynamic> lock;

  @override
  Widget build(BuildContext context) {
    final locker = lock['locker'] as Map<String, dynamic>?;
    final firmName = locker?['firm_name'] as String? ?? 'Unknown';
    final location = locker?['firm_location'] as String? ?? '';
    final status = lock['status'] as String? ?? 'locked';
    final lockedOn = lock['locked_on'] as String? ?? '';
    final unlockedOn = lock['unlocked_on'] as String?;
    final note = lock['note'] as String?;
    final isLocked = status == 'locked';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(firmName, style: AppTypography.cardTitle),
                if (location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(location, style: AppTypography.bodySm),
                  ),
                if (lockedOn.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Locked: ${lockedOn.split('T').first}',
                      style: AppTypography.caption,
                    ),
                  ),
                if (unlockedOn != null && unlockedOn.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Unlocked: ${unlockedOn.split('T').first}',
                      style: AppTypography.caption,
                    ),
                  ),
                if (note != null && note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Reason: $note',
                      style: AppTypography.bodySm.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isLocked ? AppColors.blockBlush : AppColors.blockMint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              status.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: isLocked ? AppColors.signalRed : AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final firmName = _resolveName(event, 'firm');
    final eventType = event['event_type'] as String? ?? 'unknown';
    final eventAt = event['event_at'] as String? ?? '';

    // Resolve location from the firm map
    final firmMap = event['firm'] as Map<String, dynamic>?;
    final location = firmMap?['firm_location'] as String? ?? '';

    final isLocked = eventType == 'locked';
    final badgeColor = isLocked ? AppColors.blockBlush : AppColors.blockMint;
    final textColor = isLocked ? AppColors.signalRed : AppColors.success;
    final label = isLocked ? 'Locked' : 'Unlocked';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(firmName, style: AppTypography.cardTitle),
                if (location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(location, style: AppTypography.bodySm),
                  ),
                if (eventAt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      eventAt.split('T').first,
                      style: AppTypography.caption,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}