import 'package:supabase_flutter/supabase_flutter.dart';

class AppVersionInfo {
  final String latestVersion;
  final String apkUrl;
  final String? releaseNotes;
  final bool forceUpdate;

  AppVersionInfo({
    required this.latestVersion,
    required this.apkUrl,
    this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    return AppVersionInfo(
      latestVersion: map['latest_version'] as String,
      apkUrl: map['apk_url'] as String,
      releaseNotes: map['release_notes'] as String?,
      forceUpdate: map['force_update'] as bool? ?? false,
    );
  }
}

class UpdateRepository {
  final _client = Supabase.instance.client;

  Future<AppVersionInfo?> getLatestVersionInfo() async {
    final row = await _client
        .from('app_version_info')
        .select()
        .eq('id', 1)
        .maybeSingle();

    if (row == null) return null;
    return AppVersionInfo.fromMap(row);
  }
}