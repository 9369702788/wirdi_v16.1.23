
class MoonSightingInfo {
  final String date;
  final String hijriMonth;
  final String visibility;
  final String location;
  final String description;
  
  const MoonSightingInfo({
    required this.date,
    required this.hijriMonth,
    required this.visibility,
    required this.location,
    required this.description,
  });
}

class MoonSightingService {
  static const List<MoonSightingInfo> sightingData = [
    MoonSightingInfo(
      date: 'Today',
      hijriMonth: 'Ramadan',
      visibility: 'Visible',
      location: 'Middle East',
      description: 'Moon will be visible in the evening',
    ),
  ];
  
  static Future<MoonSightingInfo?> getMoonSightingInfo() async {
    return sightingData.isNotEmpty ? sightingData.first : null;
  }
}
