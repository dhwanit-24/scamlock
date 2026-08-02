import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen>
    with WidgetsBindingObserver {
  final _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _auditEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAuditLog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAuditLog();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadAuditLog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await _adminRepository.getAuditLog();
      if (!mounted) return;
      setState(() {
        _auditEntries = entries;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Load audit log error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load audit log. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  Color _actionColor(String actionType) {
    switch (actionType) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.orange;
      case 'activated':
        return Colors.blue;
      default:
        return Colors.black54;
    }
  }

  String _actionLabel(String actionType) {
    switch (actionType) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      case 'activated':
        return 'Activated';
      default:
        return actionType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAuditLog,
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
                        onPressed: _loadAuditLog,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_auditEntries.isEmpty) {
              return const Center(
                child: Text('No actions recorded yet.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _auditEntries.length,
              itemBuilder: (context, index) {
                final entry = _auditEntries[index];
                final actionType = entry['action'] as String? ?? 'unknown';
                final target = entry['target'] as Map<String, dynamic>?;
                final firmName = target?['firm_name'] as String? ?? 'Unknown';
                final fullName = target?['full_name'] as String? ?? '';
                final createdAt = entry['created_at'] as String? ?? '';
                final note = entry['note'] as String?;

                final dateLabel = createdAt.isNotEmpty
                    ? createdAt.split('T').first
                    : '';
                final timeLabel = createdAt.contains('T')
                    ? createdAt.split('T')[1].split('Z').first
                    : '';

                return _AuditEntryCard(
                  actionType: actionType,
                  actionLabel: _actionLabel(actionType),
                  actionColor: _actionColor(actionType),
                  firmName: firmName,
                  fullName: fullName,
                  dateLabel: dateLabel,
                  timeLabel: timeLabel,
                  note: note,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AuditEntryCard extends StatelessWidget {
  const _AuditEntryCard({
    required this.actionType,
    required this.actionLabel,
    required this.actionColor,
    required this.firmName,
    required this.fullName,
    required this.dateLabel,
    required this.timeLabel,
    required this.note,
  });

  final String actionType;
  final String actionLabel;
  final Color actionColor;
  final String firmName;
  final String fullName;
  final String dateLabel;
  final String timeLabel;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    firmName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (fullName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                fullName,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note: $note',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}