
class AmbianceService {
  static const List<String> ambianceOptions = [
    'None',
    'Rain Sound',
    'Ocean Waves',
    'Birds Chirping',
    'Forest Ambiance',
    'Meditation Bell',
  ];
  
  static Future<void> setAmbiance(String ambianceType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ambiance', ambianceType);
  }
}
