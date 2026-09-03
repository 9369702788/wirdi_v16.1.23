
class PrayerTimeChart {
  final String prayerName;
  final String time;
  final int minutesFromFajr;
  final String color;
  
  const PrayerTimeChart({
    required this.prayerName,
    required this.time,
    required this.minutesFromFajr,
    required this.color,
  });
}

class PrayerChartService {
  static Future<List<PrayerTimeChart>> getPrayerTimesChart() async {
    return [
      PrayerTimeChart(
        prayerName: 'Fajr',
        time: '05:30 AM',
        minutesFromFajr: 0,
        color: '#FF6B6B',
      ),
      PrayerTimeChart(
        prayerName: 'Dhuhr',
        time: '12:30 PM',
        minutesFromFajr: 420,
        color: '#4ECDC4',
      ),
      PrayerTimeChart(
        prayerName: 'Asr',
        time: '03:45 PM',
        minutesFromFajr: 615,
        color: '#FFE66D',
      ),
      PrayerTimeChart(
        prayerName: 'Maghrib',
        time: '06:30 PM',
        minutesFromFajr: 900,
        color: '#FF9999',
      ),
      PrayerTimeChart(
        prayerName: 'Isha',
        time: '08:00 PM',
        minutesFromFajr: 1050,
        color: '#95E1D3',
      ),
    ];
  }
}
