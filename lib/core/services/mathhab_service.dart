import 'package:shared_preferences/shared_preferences.dart';

class MathhabService {
  static const List<String> mathhabs = [
    'Hanafi',
    'Maliki',
    'Shafi\'i',
    'Hanbali',
  ];
  
  static Future<void> setMathhab(String mathhab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_mathhab', mathhab);
  }
  
  static Future<String> getMathhab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_mathhab') ?? 'Hanafi';
  }
  
  static Future<Map<String, dynamic>> getPrayerTimesForMathhab(String mathhab) async {
    return {
      'asr_calculation': mathhab == 'Hanafi' ? 'Standard' : 'Shadow ratio',
      'maghrib_isha_gap': mathhab == 'Maliki' ? '30 min' : '20 min',
    };
  }
}
