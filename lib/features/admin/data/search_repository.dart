import 'package:supabase_flutter/supabase_flutter.dart';

class SearchRepository {
  SearchRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> searchTrackedPeople({
    required String query,
  }) async {
    final trimmed = query.trim();

    final response = await _client
        .from('tracked_people')
        .select('''
      *,
      locks:person_locks(count)
    ''')
        .or(
          'full_name.ilike.%$trimmed%,phone_no.ilike.%$trimmed%,g_number.ilike.%$trimmed%,a_number.ilike.%$trimmed%',
        )
        .order('created_at', ascending: false);

    return response;
  }

  Future<List<Map<String, dynamic>>> findExistingPerson({
    String? phone,
    String? gNumber,
    String? aNumber,
  }) async {
    var builder = _client
        .from('tracked_people')
        .select('id, full_name, phone_no, g_number, a_number, description');

    final conditions = <String>[];
    if (phone != null && phone.isNotEmpty) {
      conditions.add('phone_no.eq.$phone');
    }
    if (gNumber != null && gNumber.isNotEmpty) {
      conditions.add('g_number.eq.$gNumber');
    }
    if (aNumber != null && aNumber.isNotEmpty) {
      conditions.add('a_number.eq.$aNumber');
    }

    if (conditions.isEmpty) return [];

    final filter = conditions.join(',');
    final response = await builder.or(filter);
    return response;
  }

  Future<Map<String, dynamic>> createTrackedPerson({
    required String fullName,
    required String phoneNo,
    String? gNumber,
    String? aNumber,
    String? description,
  }) async {
    final response = await _client
        .from('tracked_people')
        .insert({
          'full_name': fullName,
          'phone_no': phoneNo,
          if (gNumber != null && gNumber.isNotEmpty) 'g_number': gNumber,
          if (aNumber != null && aNumber.isNotEmpty) 'a_number': aNumber,
          if (description != null && description.isNotEmpty)
            'description': description,
        })
        .select()
        .single();

    return response;
  }

  Future<void> createPersonLock(String personId, {String? note}) async {
    final currentUserId = _client.auth.currentUser!.id;

    final existingLock = await _client
        .from('person_locks')
        .select('id')
        .eq('person_id', personId)
        .eq('locked_by', currentUserId)
        .maybeSingle();

    if (existingLock != null) {
      await _client
          .from('person_locks')
          .update({
        'status': 'locked',
        'locked_on': DateTime.now().toUtc().toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
      })
          .eq('id', existingLock['id']);
      return;
    }

    await _client.from('person_locks').insert({
      'person_id': personId,
      'locked_by': currentUserId,
      'status': 'locked',
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> getPersonLocks(String personId) async {
    final response = await _client
        .from('person_locks')
        .select('''
      *,
      locker:profiles!locked_by(full_name, firm_name, firm_location)
    ''')
        .eq('person_id', personId)
        .order('locked_on', ascending: false);

    return response;
  }

  Future<List<Map<String, dynamic>>> getPersonLockEvents(
    String personId,
  ) async {
    final response = await _client
        .from('person_lock_events')
        .select('''
      *,
      firm:profiles!firm_id(full_name, firm_name, firm_location)
    ''')
        .eq('person_id', personId)
        .order('event_at', ascending: false);

    return response;
  }
  Future<Map<String, dynamic>?> findMyLock(String personId) async {
    final response = await _client
        .from('person_locks')
        .select()
        .eq('person_id', personId)
        .eq('locked_by', _client.auth.currentUser!.id)
        .maybeSingle();
    return response;
  }

  Future<void> updateMyLockStatus(String personId, String status) async {
    await _client
        .from('person_locks')
        .update({'status': status})
        .eq('person_id', personId)
        .eq('locked_by', _client.auth.currentUser!.id);
  }
  Future<List<Map<String, dynamic>>> getMyLockedPeople() async {
  final currentUserId = _client.auth.currentUser!.id;

  final response = await _client
      .from('person_locks')
      .select('''
        *,
        person:tracked_people!person_id(
          id, full_name, phone_no, g_number, a_number, description, created_at
        ,locks:person_locks(count))
      ''')
      .eq('locked_by', currentUserId)
      .eq('status', 'locked')
      .order('locked_on', ascending: false);
  return response;
}

  Future<Map<String, dynamic>?> getLockingFirmDetails({
    required String personId,
    required String firmId,
  }) async {
    final result = await _client.rpc(
      'get_locking_firm_details',
      params: {
        'p_person_id': personId,
        'p_firm_id': firmId,
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(result.first);
  }
}