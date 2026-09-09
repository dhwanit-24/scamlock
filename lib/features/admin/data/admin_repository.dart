import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  AdminRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('account_status', 'pending')
        .order('created_at', ascending: true);

    return response;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    return response;
  }

  Future<void> updateUserStatus({
    required String userId,
    required String status,
    required String actionType,
  }) async {
    await _client.rpc('update_user_status_with_audit', params: {
      'p_user_id': userId,
      'p_new_status': status,
      'p_action': actionType,
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLog() async {
    final response = await _client
        .from('admin_actions')
        .select('''
      *,
      target:profiles!target_user_id(full_name, firm_name)
    ''')
        .order('created_at', ascending: false);

    return response;
  }
}