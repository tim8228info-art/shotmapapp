// ────────────────────────────────────────────────────────────────────────────
// UGC Moderation Service  – Report & Block persistence layer
//
// Apple Guideline 1.2 / 2.1 compliance:
//   - Reports are stored locally via Hive and can be synced to a backend.
//   - Blocked users are persisted; their content is filtered from all feeds.
//
// Storage: Hive boxes
//   - 'ugc_reports'  → List<Map> of filed reports
//   - 'ugc_blocked'  → Set<String> of blocked user IDs / names
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UgcModerationService {
  static const String _reportsBoxName = 'ugc_reports';
  static const String _blockedBoxName = 'ugc_blocked';

  static late Box<Map> _reportsBox;
  static late Box<String> _blockedBox;

  /// Initialize Hive boxes. Call once in main() after Hive.initFlutter().
  static Future<void> init() async {
    _reportsBox = await Hive.openBox<Map>(_reportsBoxName);
    _blockedBox = await Hive.openBox<String>(_blockedBoxName);
    if (kDebugMode) {
      debugPrint('[UGC] Moderation service initialized '
          '(reports: ${_reportsBox.length}, blocked: ${_blockedBox.length})');
    }
  }

  // ─── Report ────────────────────────────────────────────────────────────

  /// Submit a content report. Persists locally and (TODO) syncs to server.
  static Future<void> submitReport({
    required String postId,
    required String reason,
    String? authorId,
    String? authorName,
  }) async {
    final report = <String, dynamic>{
      'postId': postId,
      'reason': reason,
      'authorId': authorId ?? '',
      'authorName': authorName ?? '',
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };
    await _reportsBox.add(report);
    if (kDebugMode) {
      debugPrint('[UGC] Report filed: postId=$postId reason=$reason');
    }

    // TODO: In production, send to your moderation API here.
    // Example:
    // await http.post(Uri.parse('https://api.shotmap.app/v1/reports'), body: report);
    // Then mark report['synced'] = true and save again.
  }

  /// Returns all locally stored reports (for admin / debug use).
  static List<Map> getAllReports() {
    return _reportsBox.values.toList();
  }

  /// Check if a specific post has already been reported by this user.
  static bool isPostReported(String postId) {
    return _reportsBox.values.any((r) => r['postId'] == postId);
  }

  // ─── Block ─────────────────────────────────────────────────────────────

  /// Block a user. Content from blocked users will be hidden.
  static Future<void> blockUser(String userIdentifier) async {
    if (userIdentifier.isEmpty) return;
    // Avoid duplicates
    if (!isBlocked(userIdentifier)) {
      await _blockedBox.add(userIdentifier);
    }
    if (kDebugMode) {
      debugPrint('[UGC] Blocked user: $userIdentifier');
    }

    // TODO: In production, sync block list to backend.
  }

  /// Unblock a user.
  static Future<void> unblockUser(String userIdentifier) async {
    final keys = _blockedBox.keys.where(
      (key) => _blockedBox.get(key) == userIdentifier,
    );
    for (final key in keys) {
      await _blockedBox.delete(key);
    }
    if (kDebugMode) {
      debugPrint('[UGC] Unblocked user: $userIdentifier');
    }
  }

  /// Check if a user is blocked.
  static bool isBlocked(String userIdentifier) {
    return _blockedBox.values.contains(userIdentifier);
  }

  /// Get all blocked user identifiers.
  static Set<String> get blockedUsers => _blockedBox.values.toSet();

  /// Clear all blocked users (e.g., on account deletion).
  static Future<void> clearAll() async {
    await _reportsBox.clear();
    await _blockedBox.clear();
  }
}
