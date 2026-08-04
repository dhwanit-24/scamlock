import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import 'package:flutter/services.dart';

class LockPersonScreen extends StatefulWidget {
  const LockPersonScreen({super.key});

  @override
  State<LockPersonScreen> createState() => _LockPersonScreenState();
}

class _LockPersonScreenState extends State<LockPersonScreen> {
  final _searchRepository = SearchRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gNumberController = TextEditingController();
  final _aNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  bool _isChecking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gNumberController.dispose();
    _aNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleLock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChecking = true;
    });

    List<Map<String, dynamic>> existing = [];
    try {
      final trimmedG = _gNumberController.text.trim();
      final trimmedA = _aNumberController.text.trim();

      final results = await _searchRepository.findExistingPerson(
        phone: _phoneController.text.trim(),
        gNumber: trimmedG.isNotEmpty ? trimmedG.toUpperCase() : null,
        aNumber: trimmedA.isNotEmpty ? trimmedA : null,
      );

      existing = results;
    } catch (error) {
      debugPrint('Lock person check error: $error');
    }

    if (!mounted) return;

    if (existing.isNotEmpty) {
      final person = existing.first;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/confirm-lock',
        arguments: {
          'existingPerson': person,
          'description': _descriptionController.text.trim(),
        },
      );
      return;
    }

    setState(() {
      _isChecking = false;
      _isSubmitting = true;
    });

    try {
      final trimmedG = _gNumberController.text.trim();
      final trimmedA = _aNumberController.text.trim();

      final created = await _searchRepository.createTrackedPerson(
        fullName: _nameController.text.trim(),
        phoneNo: _phoneController.text.trim(),
        gNumber: trimmedG.isNotEmpty ? trimmedG.toUpperCase() : null,
        aNumber: trimmedA.isNotEmpty ? trimmedA : null,
        description: _descriptionController.text.trim(),
      );

      await _searchRepository.createPersonLock(
        created['id'] as String,
        note: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Person locked successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('Lock person error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lock a Person'),
      ),
      body: SafeArea(
        child: _isChecking
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48),
                      child: LinearProgressIndicator(),
                    ),
                    SizedBox(height: 24),
                    Text('Checking records...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the person\'s full name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          hintText: '10 digits',
                        ),
                        validator: (value) {
                          final digits =
                              value?.replaceAll(RegExp(r'\D'), '') ?? '';
                          if (!RegExp(r'^\d{10}$').hasMatch(digits)) {
                            return 'Enter a valid 10-digit phone number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gNumberController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(15),
                          TextInputFormatter.withFunction(
                                (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                            ),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'G Number (optional)',
                          border: OutlineInputBorder(),
                          hintText: '15 alphanumeric characters',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _aNumberController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'A Number (optional)',
                          border: OutlineInputBorder(),
                          hintText: '12 digits',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _handleLock,
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
                              : const Text('Lock Person'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      );
  }
}