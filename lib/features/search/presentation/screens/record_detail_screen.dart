import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';

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
        title: Text(hasActiveLock ? 'Unlock this person?' : 'Lock this person?'),
        content: Text(
          hasActiveLock
              ? 'Your firm\'s lock will be removed. Other firms\' locks remain.'
              : 'Your firm will flag this person.',
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
      appBar: AppBar(
        title: const Text('Record Detail'),
        actions: [
          if (_person != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _toggleMyLock,
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Builder(
                builder: (context) {
                  if (_isLoading && _person == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
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
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
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
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (_person != null) _PersonInfoCard(person: _person!),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Locked By',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_locks.isEmpty)
                          const Text('No locks yet.')
                        else
                          ..._locks.map(
                            (lock) => _LockCard(lock: lock),
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          'Lock History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_events.isEmpty)
                          const Text('No history yet.')
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              person['full_name'] as String? ?? 'Unknown',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('+91 ${person['phone_no'] as String? ?? ''}'),
            if (person['g_number'] != null &&
                (person['g_number'] as String).isNotEmpty)
              Text('G Number: ${person['g_number']}'),
            if (person['a_number'] != null &&
                (person['a_number'] as String).isNotEmpty)
              Text('A Number: ${person['a_number']}'),
            if ((person['description'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description: ${person['description']}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(firmName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.isNotEmpty) Text(location),
            if (lockedOn.isNotEmpty)
              Text(
                'Locked: ${lockedOn.split('T').first}',
                style: const TextStyle(fontSize: 12),
              ),
            if (unlockedOn != null && unlockedOn.isNotEmpty)
              Text(
                'Unlocked: ${unlockedOn.split('T').first}',
                style: const TextStyle(fontSize: 12),
              ),
            if (note != null && note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Reason: $note',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        trailing: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: status == 'locked' ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
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

    final color = eventType == 'locked' ? Colors.red : Colors.green;
    final label = eventType == 'locked' ? 'Locked' : 'Unlocked';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(firmName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.isNotEmpty) Text(location),
            if (eventAt.isNotEmpty)
              Text(
                eventAt.split('T').first,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
