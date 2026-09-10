import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/support_repository.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _repository = SupportRepository();
  Map<String, dynamic>? _contact;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contact = await _repository.getContact();
      if (!mounted) return;

      setState(() {
        _contact = contact;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load support contact details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launch(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show the same user-facing failure state below.
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No app is available for this action.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Contact the developer'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _isLoading
                ? const CircularProgressIndicator(color: AppColors.ink)
                : _errorMessage != null
                ? _MessageState(
              message: _errorMessage!,
              onPressed: _loadContact,
            )
                : _contact == null
                ? _MessageState(
              message:
              'Support contact details have not been configured yet.',
              onPressed: _loadContact,
            )
                : _ContactDetails(
              contact: _contact!,
              onCall: () => _launch(
                Uri(
                  scheme: 'tel',
                  path: _contact!['phone_e164'] as String,
                ),
              ),
              onEmail: () => _launch(
                Uri(
                  scheme: 'mailto',
                  path: _contact!['email'] as String,
                ),
              ),
              onWhatsApp: () => _launch(
                Uri.https(
                  'wa.me',
                  '/${(_contact!['phone_e164'] as String).replaceFirst('+', '')}',
                  {'text': 'Hello, I need help with ScamLock.'},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.onPressed,
  });

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center, style: AppTypography.body),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails({
    required this.contact,
    required this.onCall,
    required this.onEmail,
    required this.onWhatsApp,
  });

  final Map<String, dynamic> contact;
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final name = contact['name'] as String;
    final phone = contact['phone_e164'] as String;
    final email = contact['email'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.support_agent, size: 56, color: AppColors.signalRed),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Contact the developer',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(name, textAlign: TextAlign.center, style: AppTypography.cardTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(phone, textAlign: TextAlign.center, style: AppTypography.body),
        Text(email, textAlign: TextAlign.center, style: AppTypography.body),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone_outlined),
          label: const Text('Call'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onEmail,
          icon: const Icon(Icons.email_outlined),
          label: const Text('Email'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onWhatsApp,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('WhatsApp'),
        ),
      ],
    );
  }
}