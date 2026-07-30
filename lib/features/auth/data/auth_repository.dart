import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _developmentAuthDomain = 'dev.scamlock.invalid';

  Future<void> requestAccess({
    required String fullName,
    required String firmName,
    required String phone,
    required String firmLocation,
    required String password,
    String? email,
  }) async {
    final phoneDigits = _phoneDigits(phone);
    final developmentAuthEmail = _developmentEmailFor(phoneDigits);

    await _client.auth.signUp(
      email: developmentAuthEmail,
      password: password,
      data: {
        'full_name': fullName.trim(),
        'firm_name': firmName.trim(),
        'phone': phoneDigits,
        'email': email?.trim() ?? '',
        'firm_location': firmLocation.trim(),
      },
    );
  }

  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    final phoneDigits = _phoneDigits(phone);
    final developmentAuthEmail = _developmentEmailFor(phoneDigits);

    await _client.auth.signInWithPassword(
      email: developmentAuthEmail,
      password: password,
    );
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  String _phoneDigits(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) {
      throw const FormatException(
        'Enter a valid 10-digit phone number.',
      );
    }

    return digitsOnly;
  }

  String _developmentEmailFor(String phoneDigits) {
    return '$phoneDigits@$_developmentAuthDomain';
  }
}