import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wraps the Google Geocoding + Places APIs.
///
/// Requires these APIs enabled in Google Cloud Console:
///   - Geocoding API          → reverseGeocode, forwardGeocode
///   - Places API (New)       → getSuggestions, getPlaceDetail
///
/// API key is read from GOOGLE_MAPS_API_KEY in the frontend/.env file.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const _autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _placeDetailUrl = 'https://maps.googleapis.com/maps/api/place/details/json';

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  // ── 1. Reverse Geocode: lat/lng → address ─────────────────────────────────

  Future<String?> reverseGeocode(double lat, double lng) async {
    if (_apiKey.isEmpty) return null;
    try {
      final res = await _dio.get(_geocodeUrl, queryParameters: {
        'latlng': '$lat,$lng',
        'key': _apiKey,
      });

      if (res.data['status'] != 'OK') return null;
      final results = res.data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      // Try to find a neighborhood or locality-level result for a clean label
      for (final result in results) {
        final types = (result['types'] as List).cast<String>();
        if (types.contains('neighborhood') ||
            types.contains('sublocality') ||
            types.contains('locality')) {
          return result['formatted_address'] as String?;
        }
      }
      return results.first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── 2. Forward Geocode: address → lat/lng ─────────────────────────────────

  Future<GeocodedPlace?> forwardGeocode(String address) async {
    if (_apiKey.isEmpty || address.trim().isEmpty) return null;
    try {
      final res = await _dio.get(_geocodeUrl, queryParameters: {
        'address': address,
        'key': _apiKey,
        'region': 'NP',
      });

      if (res.data['status'] != 'OK') return null;
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

  // ── 3. Autocomplete: partial text → suggestions ───────────────────────────
  // Requires "Places API" enabled in Google Cloud Console.
  // Falls back to empty list if the API returns an error (e.g. not enabled).

  Future<List<PlaceSuggestion>> getSuggestions(
      String input, {
        double? lat,
        double? lng,
      }) async {
    if (_apiKey.isEmpty || input.trim().length < 2) return [];
    try {
      final params = <String, dynamic>{
        'input': input,
        'key': _apiKey,
        'language': 'en',
        'components': 'country:NP',
      };
      if (lat != null && lng != null) {
        params['location'] = '$lat,$lng';
        params['radius'] = '50000';
      }

      final res = await _dio.get(_autocompleteUrl, queryParameters: params);

      // 'REQUEST_DENIED' usually means Places API not enabled
      if (res.data['status'] == 'REQUEST_DENIED') {
        // Fall back to forward geocode suggestion
        final place = await forwardGeocode(input);
        if (place == null) return [];
        return [
          PlaceSuggestion(
            placeId: place.placeId ?? '',
            description: place.formattedAddress,
            mainText: place.formattedAddress,
            secondaryText: '',
            lat: place.latitude,
            lng: place.longitude,
          )
        ];
      }

      final predictions = res.data['predictions'] as List? ?? [];
      return predictions.map((p) => PlaceSuggestion(
        placeId: p['place_id'] as String,
        description: p['description'] as String,
        mainText: p['structured_formatting']?['main_text'] as String? ?? p['description'] as String,
        secondaryText: p['structured_formatting']?['secondary_text'] as String? ?? '',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 4. Place Detail: placeId → lat/lng ───────────────────────────────────
  // If placeId is empty (fallback from getSuggestions), lat/lng already known.

  Future<GeocodedPlace?> getPlaceDetail(String placeId, {double? lat, double? lng}) async {
    // If we already have coordinates (from fallback), return them directly
    if (placeId.isEmpty && lat != null && lng != null) {
      return GeocodedPlace(latitude: lat, longitude: lng, formattedAddress: '');
    }

    if (_apiKey.isEmpty || placeId.isEmpty) return null;
    try {
      final res = await _dio.get(_placeDetailUrl, queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address,name',
        'key': _apiKey,
      });

      if (res.data['status'] == 'REQUEST_DENIED') return null;
      final result = res.data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final loc = result['geometry']['location'];
      return GeocodedPlace(
        latitude: (loc['lat'] as num).toDouble(),
        longitude: (loc['lng'] as num).toDouble(),
        formattedAddress: result['formatted_address'] as String? ?? result['name'] as String? ?? '',
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
  // Optional pre-resolved coords (used when Places API not available)
  final double? lat;
  final double? lng;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.lat,
    this.lng,
  });
}