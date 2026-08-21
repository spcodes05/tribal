import 'package:dio/dio.dart';

/// Wraps Open-Meteo's current-weather API.
///
/// Free, no API key required, no rate-limit headaches — good fit for a
/// student project. Docs: https://open-meteo.com/en/docs
///
/// Given the activity's latitude/longitude (already stored on Activity),
/// this returns the current temperature + a simple weather condition
/// derived from Open-Meteo's WMO weather code.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  // Small in-memory cache keyed by rounded lat/lng so re-opening the same
  // activity detail screen within a session doesn't refire the request.
  final Map<String, _CachedWeather> _cache = {};
  static const _cacheTtl = Duration(minutes: 15);

  Future<ActivityWeather?> getCurrentWeather(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return cached.weather;
    }

    try {
      final res = await _dio.get(_baseUrl, queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      });

      final current = res.data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final code = current['weather_code'] as int?;
      if (temp == null || code == null) return null;

      final weather = ActivityWeather(
        temperatureCelsius: temp,
        condition: _conditionFromCode(code),
        icon: _iconFromCode(code),
      );
      _cache[key] = _CachedWeather(weather, DateTime.now());
      return weather;
    } catch (_) {
      return null;
    }
  }

  // Maps Open-Meteo's WMO weather codes to a short label + emoji icon.
  // https://open-meteo.com/en/docs#weather_variable_documentation
  String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 2) return 'Partly cloudy';
    if (code == 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 85 && code <= 86) return 'Snow showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Clear';
  }

  String _iconFromCode(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '🌤️';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 85 && code <= 86) return '🌨️';
    if (code >= 95) return '⛈️';
    return '☀️';
  }
}

class _CachedWeather {
  final ActivityWeather weather;
  final DateTime fetchedAt;
  _CachedWeather(this.weather, this.fetchedAt);
}

class ActivityWeather {
  final double temperatureCelsius;
  final String condition;
  final String icon;

  const ActivityWeather({
    required this.temperatureCelsius,
    required this.condition,
    required this.icon,
  });
}