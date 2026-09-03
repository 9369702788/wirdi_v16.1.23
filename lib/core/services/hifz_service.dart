import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HifzPlan {
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final int targetReps;

  const HifzPlan({
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.targetReps,
  });
}

/// Persists Hifz (memorization) progress: how many times each ayah has
/// been repeated TODAY, the current daily plan (surah + ayah range +
/// target repeats per ayah), and a simple day-streak counter for
/// fully-completed plans. Plain SharedPreferences key/value pairs --
/// consistent with the rest of the app, intentionally simple: this is
/// a practice aid, not a scientific spaced-repetition system.
class HifzService {
  HifzService._();

  static const _planKey = 'hifz_plan_v1';
  static const _repsPrefix = 'hifz_reps_v1_';
  static const _streakKey = 'hifz_streak_v1';
  static const _lastCompletedDateKey = 'hifz_last_completed_date_v1';
  static const _revisionKey = 'hifz_revision_portions_v1';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _repKey(int surahNumber, int ayahNumber) =>
      '$_repsPrefix${surahNumber}_${ayahNumber}_${_todayKey()}';

  static Future<int> getTodayReps(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_repKey(surahNumber, ayahNumber)) ?? 0;
  }

  static Future<int> incrementReps(int surahNumber, int ayahNumber, int cap) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _repKey(surahNumber, ayahNumber);
    final current = prefs.getInt(key) ?? 0;
    final next = current >= cap ? current : current + 1;
    await prefs.setInt(key, next);
    return next;
  }

  static Future<HifzPlan?> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final surahNumber = prefs.getInt('${_planKey}_surah');
    final startAyah = prefs.getInt('${_planKey}_start');
    final endAyah = prefs.getInt('${_planKey}_end');
    final targetReps = prefs.getInt('${_planKey}_target');
    if (surahNumber == null || startAyah == null || endAyah == null || targetReps == null) {
      return null;
    }
    return HifzPlan(surahNumber: surahNumber, startAyah: startAyah, endAyah: endAyah, targetReps: targetReps);
  }

  static Future<void> setPlan(HifzPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_planKey}_surah', plan.surahNumber);
    await prefs.setInt('${_planKey}_start', plan.startAyah);
    await prefs.setInt('${_planKey}_end', plan.endAyah);
    await prefs.setInt('${_planKey}_target', plan.targetReps);
  }

  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_planKey}_surah');
    await prefs.remove('${_planKey}_start');
    await prefs.remove('${_planKey}_end');
    await prefs.remove('${_planKey}_target');
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  static Future<int> checkAndUpdateStreakIfPlanCompleted() async {
    final plan = await getPlan();
    final prefs = await SharedPreferences.getInstance();
    if (plan == null) return prefs.getInt(_streakKey) ?? 0;

    final todayStr = _todayKey();
    final lastCompleted = prefs.getString(_lastCompletedDateKey);
    if (lastCompleted == todayStr) {
      return prefs.getInt(_streakKey) ?? 0;
    }

    for (var a = plan.startAyah; a <= plan.endAyah; a++) {
      final reps = await getTodayReps(plan.surahNumber, a);
      if (reps < plan.targetReps) {
        return prefs.getInt(_streakKey) ?? 0;
      }
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final twoDaysAgoStr =
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';
    final currentStreak = prefs.getInt(_streakKey) ?? 0;
    await _grantMonthlyStreakFreezeIfDue(prefs);
    final freezesAvailable = prefs.getInt(_freezesKey) ?? 0;

    int newStreak;
    if (lastCompleted == yesterdayStr) {
      newStreak = currentStreak + 1;
    } else if (lastCompleted == twoDaysAgoStr && freezesAvailable > 0) {
      await prefs.setInt(_freezesKey, freezesAvailable - 1);
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }
    await prefs.setInt(_streakKey, newStreak);
    await prefs.setString(_lastCompletedDateKey, todayStr);
    return newStreak;
  }

  static const _freezesKey = 'hifz_streak_freezes_available';
  static const _freezeLastGrantMonthKey = 'hifz_streak_freeze_last_grant_month';

  static Future<void> _grantMonthlyStreakFreezeIfDue(SharedPreferences prefs) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final lastGrantMonth = prefs.getString(_freezeLastGrantMonthKey);
    if (lastGrantMonth == monthKey) return;
    final current = prefs.getInt(_freezesKey) ?? 0;
    final next = current + 1 > 2 ? 2 : current + 1;
    await prefs.setInt(_freezesKey, next);
    await prefs.setString(_freezeLastGrantMonthKey, monthKey);
  }

  static Future<int> streakFreezesAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    await _grantMonthlyStreakFreezeIfDue(prefs);
    return prefs.getInt(_freezesKey) ?? 0;
  }

  static Future<List<Map<String, dynamic>>> _loadRevisionPortions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_revisionKey) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> _saveRevisionPortions(List<Map<String, dynamic>> portions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_revisionKey, portions.map((p) => jsonEncode(p)).toList());
  }

  static Future<void> markPortionMemorized(int surahNumber, int startAyah, int endAyah) async {
    final portions = await _loadRevisionPortions();
    final id = '${surahNumber}_${startAyah}_$endAyah';
    portions.removeWhere((p) => p['id'] == id);
    portions.add({
      'id': id,
      'surah': surahNumber,
      'start': startAyah,
      'end': endAyah,
      'lastRevisedAt': DateTime.now().toIso8601String(),
    });
    await _saveRevisionPortions(portions);
  }

  static Future<void> markPortionRevised(String id) async {
    final portions = await _loadRevisionPortions();
    for (final p in portions) {
      if (p['id'] == id) p['lastRevisedAt'] = DateTime.now().toIso8601String();
    }
    await _saveRevisionPortions(portions);
  }

  static Future<List<Map<String, dynamic>>> getPortionsDueForRevision({int intervalDays = 7}) async {
    final portions = await _loadRevisionPortions();
    final now = DateTime.now();
    return portions.where((p) {
      final last = DateTime.parse(p['lastRevisedAt'] as String);
      return now.difference(last).inDays >= intervalDays;
    }).toList();
  }

  static Future<int> totalMemorizedPortions() async {
    final portions = await _loadRevisionPortions();
    return portions.length;
  }
}
