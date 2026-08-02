import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';

/// Requests GPS permission, gets current position, and saves it to the
/// backend so the recommendation engine can compute LocationScore.
///
/// Call [requestAndSave] once after login (e.g. from HomeScreen.initState).
/// Subsequent calls are cheap — geolocator returns a cached position fast.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Returns true if coordinates were successfully saved to the backend.
  Future<bool> requestAndSave() async {
    try {
      final position = await _determinePosition();
      if (position == null) return false;
      await _saveToBackend(position.latitude, position.longitude);
      return true;
    } catch (_) {
      // Location is optional — silently fail, recommendation engine
      // falls back to 0.0 LocationScore if coords are missing.
      return false;
    }
  }

  Future<Position?> _determinePosition() async {
    // Check if location services are enabled at the device level
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,   // low accuracy is enough for km-scale matching
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> _saveToBackend(double lat, double lon) async {
    try {
      await _dio.post(
        ApiConfig.userLocation,
        data: {'latitude': double.parse(lat.toStringAsFixed(8)),
        'longitude': double.parse(lon.toStringAsFixed(8)),
        },
      );
    } on DioException catch (_) {
      // Non-critical — swallow silently
    }
  }
}
