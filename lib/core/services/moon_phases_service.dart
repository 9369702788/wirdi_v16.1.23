
class MoonPhase {
  final String phase;
  final String date;
  final double illumination;
  
  const MoonPhase({
    required this.phase,
    required this.date,
    required this.illumination,
  });
}

class MoonPhasesService {
  static Future<List<MoonPhase>> getMoonPhasesForMonth(int month, int year) async {
    return [];
  }
}
