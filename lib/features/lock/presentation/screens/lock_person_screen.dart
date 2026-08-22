import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

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
          'successRoute': '/my-locks',
        },
      );
      return;
    }

    setState(() {
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
      }
    }
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
        title: const Text('Lock a Person', style: AppTypography.cardTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.blockBlush,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 32,
                    color: AppColors.signalRed,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Add the details you have. Only phone number is '
                      'required — G/A numbers help catch repeat scammers.',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                    Icon(Icons.person_outline, color: AppColors.ink),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the person\'s full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '10 digits',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.ink,
                    ),
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
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _gNumberController,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTypography.body,
                  maxLength: 15,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9]'),
                    ),
                    TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                        text: newValue.text.toUpperCase(),
                      ),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'G Number (optional)',
                    hintText: '15 alphanumeric characters',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                  validator: (value) {
                    final gNumber = value?.trim() ?? '';

                    if (gNumber.isEmpty) {
                      return null;
                    }

                    if (!RegExp(r'^[A-Z0-9]{15}$').hasMatch(gNumber)) {
                      return 'G Number must contain exactly 15 alphanumeric characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _aNumberController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body,
                  maxLength: 12,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'A Number (optional)',
                    hintText: '12 digits',
                    prefixIcon: Icon(
                      Icons.pin_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                  validator: (value) {
                    final digits = value?.trim() ?? '';

                    if (digits.isEmpty) {
                      return null;
                    }

                    if (!RegExp(r'^\d{12}$').hasMatch(digits)) {
                      return 'A Number must contain exactly 12 digits.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined,
                        color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _isSubmitting ? null : _handleLock,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.canvas,
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