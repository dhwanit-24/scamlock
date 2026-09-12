import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/update_repository.dart';

Future<void> showUpdateDialog(
    BuildContext context,
    AppVersionInfo info,
    ) {
  return showDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (context) {
      return PopScope(
        canPop: !info.forceUpdate,
        child: AlertDialog(
          title: const Text('Update available'),
          content: Text(
            info.releaseNotes?.isNotEmpty == true
                ? info.releaseNotes!
                : 'A new version (${info.latestVersion}) is available.',
          ),
          actions: [
            if (!info.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(info.apkUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Update now'),
            ),
          ],
        ),
      );
    },
  );
}