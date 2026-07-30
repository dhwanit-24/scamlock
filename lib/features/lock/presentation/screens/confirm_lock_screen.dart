import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';

class ConfirmLockScreen extends StatefulWidget {
  const ConfirmLockScreen({super.key});

  @override
  State<ConfirmLockScreen> createState() => _ConfirmLockScreenState();
}

class _ConfirmLockScreenState extends State<ConfirmLockScreen> {
  final _searchRepository = SearchRepository();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _person;
  String? _initialDescription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>?;
    if (args != null && _person == null) {
      _person = args['existingPerson'] as Map<String, dynamic>;
      _initialDescription = args['description'] as String?;
      _descriptionController.text =
          _initialDescription?.isNotEmpty == true
              ? _initialDescription!
              : _person!['description'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _confirmLock() async {
    if (_isSubmitting) return;

    final personId = _person?['id'] as String?;
    if (personId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _searchRepository.createPersonLock(personId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Person locked successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('Confirm lock error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;

    if (person == null) {
      return const Scaffold(
        body: Center(child: Text('No data provided.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Lock'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Card(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Your reason for locking (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _confirmLock,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Lock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}