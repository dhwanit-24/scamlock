import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

class SupportFab extends StatelessWidget {
  const SupportFab({super.key});

  Future<void> _openSupport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Need help?', style: AppTypography.cardTitle),
        content: const Text(
          'You can contact the developer for support.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, contact developer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.contactSupport);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openSupport(context),
      tooltip: 'Get help',
      icon: const Icon(Icons.help_outline),
      label: const Text('Help'),
    );
  }
}