import 'package:supabase_flutter/supabase_flutter.dart';

class SupportRepository {
  SupportRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> getContact() {
    return _client
        .from('support_contact')
        .select('name, phone_e164, email')
        .eq('id', true)
        .maybeSingle();
  }
}