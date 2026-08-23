import 'package:flutter/material.dart';
import '../../../admin/data/search_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialogs.dart';

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
  String? _successRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>?;
    if (args != null && _person == null) {
      _person = args['existingPerson'] as Map<String, dynamic>;
      _initialDescription = args['description'] as String?;
      _descriptionController.text = _initialDescription ?? '';
      _successRoute = args['successRoute'] as String?;
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
      await _searchRepository.createPersonLock(personId, note: _descriptionController.text.trim());

      if (!mounted) return;
      await AppDialogs.showSuccess(
        context,
        title: 'Person locked',
        message: 'This person has been successfully added to your locks.',
      );
      if (!mounted) return;
      if (_successRoute != null) {
        Navigator.of(context).pushReplacementNamed(_successRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } catch (error) {
      debugPrint('Confirm lock error: $error');
      if (!mounted) return;
      await AppDialogs.showError(
        context,
        title: 'Unable to lock person',
        message: 'Something went wrong. Please try again.',
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
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Text('No data provided.', style: AppTypography.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text('Confirm Lock', style: AppTypography.cardTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.blockCream,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'This person is already on record',
                            style: AppTypography.bodySm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: AppTypography.body,
                decoration: const InputDecoration(
                  labelText: 'Your reason for locking (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined, color: AppColors.ink),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSubmitting ? null : _confirmLock,
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