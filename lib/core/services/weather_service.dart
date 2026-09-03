
class WeatherData {
  final String temperature;
  final String condition;
  final String humidity;
  final String windSpeed;
  
  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
  });
}

class WeatherService {
  static Future<WeatherData> getWeatherAtPrayerTime(String prayer) async {
    return const WeatherData(
      temperature: '25C',
      condition: 'Clear',
      humidity: '60%',
      windSpeed: '10 km/h',
    );
  }
}
