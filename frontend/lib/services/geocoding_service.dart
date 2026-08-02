import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wraps the Google Geocoding API for three use cases:
///
///   1. [reverseGeocode] — lat/lng → human-readable address (used when
///      user drops a pin on the location picker to show a real address
///      instead of raw coordinates)
///
///   2. [forwardGeocode] — address string → lat/lng (used when user types
///      an address in the search bar on the location picker)
///
///   3. [getSuggestions] — partial address string → list of place suggestions
///      (used for the autocomplete dropdown as user types)
///
/// Reads GOOGLE_MAPS_API_KEY from the .env file.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const _baseUrl = 'https://maps.googleapis.com/maps/api';

  String get _apiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  // ── 1. Reverse Geocode ────────────────────────────────────────────────────

  /// Converts lat/lng to a human-readable address.
  /// Returns the formatted address string, or null on failure.
  ///
  /// Example: (27.7172, 85.3240) → "Kathmandu, Bagmati Province, Nepal"
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final res = await _dio.get(
        '$_baseUrl/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
        },
      );
      final results = res.data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      // Prefer a result at neighborhood/locality level for a clean label
      for (final result in results) {
        final types = (result['types'] as List).map((e) => e.toString()).toList();
        if (types.contains('neighborhood') ||
            types.contains('locality') ||
            types.contains('sublocality') ||
            types.contains('administrative_area_level_2')) {
          return result['formatted_address'] as String?;
        }
      }
      // Fall back to first result
      return results.first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── 2. Forward Geocode ────────────────────────────────────────────────────

  /// Converts an address string to lat/lng.
  /// Returns a [GeocodedPlace] or null on failure.
  ///
  /// Example: "Thamel, Kathmandu" → GeocodedPlace(lat: 27.715, lng: 85.312, ...)
  Future<GeocodedPlace?> forwardGeocode(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final res = await _dio.get(
        '$_baseUrl/geocode/json',
        queryParameters: {
          'address': address,
          'key': _apiKey,
          // Bias results toward Nepal
          'region': 'NP',
        },
      );
      final results = res.data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final loc = first['geometry']['location'];
      return GeocodedPlace(
        latitude: (loc['lat'] as num).toDouble(),
        longitude: (loc['lng'] as num).toDouble(),
        formattedAddress: first['formatted_address'] as String,
        placeId: first['place_id'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  // ── 3. Autocomplete Suggestions ───────────────────────────────────────────

  /// Returns a list of place suggestions for a partial address string.
  /// Used to power the autocomplete dropdown in the location search bar.
  Future<List<PlaceSuggestion>> getSuggestions(
      String input, {
        double? lat,
        double? lng,
      }) async {
    if (input.trim().length < 2) return [];
    try {
      final params = <String, dynamic>{
        'input': input,
        'key': _apiKey,
        'language': 'en',
        // Bias toward Nepal
        'components': 'country:NP',
      };

      // If user location is available, bias results to nearby places
      if (lat != null && lng != null) {
        params['location'] = '$lat,$lng';
        params['radius'] = '50000'; // 50km radius
      }

      final res = await _dio.get(
        '$_baseUrl/place/autocomplete/json',
        queryParameters: params,
      );

      final predictions = res.data['predictions'] as List? ?? [];
      return predictions.map((p) {
        return PlaceSuggestion(
          placeId: p['place_id'] as String,
          description: p['description'] as String,
          mainText: p['structured_formatting']?['main_text'] as String? ??
              p['description'] as String,
          secondaryText:
          p['structured_formatting']?['secondary_text'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 4. Get Place Detail from placeId ─────────────────────────────────────

  /// Resolves a [PlaceSuggestion.placeId] to actual lat/lng coordinates.
  /// Called when the user taps a suggestion in the autocomplete list.
  Future<GeocodedPlace?> getPlaceDetail(String placeId) async {
    try {
      final res = await _dio.get(
        '$_baseUrl/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry,formatted_address,name',
          'key': _apiKey,
        },
      );
      final result = res.data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final loc = result['geometry']['location'];
      return GeocodedPlace(
        latitude: (loc['lat'] as num).toDouble(),
        longitude: (loc['lng'] as num).toDouble(),
        formattedAddress: result['formatted_address'] as String? ??
            result['name'] as String? ?? '',
        placeId: placeId,
      );
    } catch (_) {
      return null;
    }
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class GeocodedPlace {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? placeId;

  const GeocodedPlace({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.placeId,
  });
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}