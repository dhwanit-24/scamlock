/// Returns true if [remote] is a newer version than [current].
/// Compares dot-separated numeric segments, e.g. "1.2.0" vs "1.10.0".
bool isNewerVersion(String current, String remote) {
  final c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final r = remote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final len = c.length > r.length ? c.length : r.length;

  for (var i = 0; i < len; i++) {
    final cv = i < c.length ? c[i] : 0;
    final rv = i < r.length ? r[i] : 0;
    if (rv > cv) return true;
    if (rv < cv) return false;
  }
  return false;
}