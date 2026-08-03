import 'package:dio/dio.dart';

/// Wraps OpenStreetMap's Nominatim search/reverse geocoding API.
///
/// Free, no API key required. Usage policy caps requests at 1/second —
/// see https://operations.osmfoundation.org/policies/nominatim/ — so this
/// service throttles itself and requires a descriptive User-Agent.
///
/// Note: the map *display* (GoogleMap widget) is unaffected by this file
/// and still uses Google Maps — this class only covers search/autocomplete
/// and reverse geocoding (the address label shown under the pin).
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  static const _searchUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // TODO: replace with a real contact (app name + email or repo URL).
  // Nominatim's usage policy requires a genuine identifying User-Agent —
  // generic/browser-like User-Agents can get silently blocked.
  static const _userAgent = 'Tribal/1.0 (spcodes0315@gmail.com)';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    headers: {'User-Agent': _userAgent},
  ));

  // ── Rate limiting: Nominatim allows max 1 request/second ──────────────────

  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _throttle() async {
    const minGap = Duration(milliseconds: 1100); // small buffer over 1s
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < minGap) {
      await Future.delayed(minGap - elapsed);
    }
    _lastRequest = DateTime.now();
  }

  // Caches full place info from getSuggestions() so getPlaceDetail() can
  // return instantly without a second network call (Nominatim's search
  // results already include coordinates + full address).
  final Map<String, GeocodedPlace> _detailCache = {};

  // ── 1. Reverse Geocode: lat/lng → address ─────────────────────────────────

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      await _throttle();
      final res = await _dio.get(_reverseUrl, queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'json',
        'addressdetails': 1,
      });

      final data = res.data;
      if (data == null || data['display_name'] == null) return null;
      return data['display_name'] as String;
    } catch (_) {
      return null;
    }
  }

  // ── 2. Forward Geocode: address → lat/lng ─────────────────────────────────

  Future<GeocodedPlace?> forwardGeocode(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      await _throttle();
      final res = await _dio.get(_searchUrl, queryParameters: {
        'q': address,
        'format': 'json',
        'addressdetails': 1,
        'limit': 1,
        'countrycodes': 'np',
      });

      final results = res.data as List?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return GeocodedPlace(
        latitude: lat,
        longitude: lon,
        formattedAddress: first['display_name'] as String? ?? '',
        placeId: first['place_id']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── 3. Autocomplete: partial text → suggestions ───────────────────────────

  Future<List<PlaceSuggestion>> getSuggestions(
      String input, {
        double? lat,
        double? lng,
      }) async {
    if (input.trim().length < 2) return [];
    try {
      await _throttle();
      final params = <String, dynamic>{
        'q': input,
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
        'countrycodes': 'np',
      };

      // Bias (not restrict) results toward the current pin position using
      // a rough ~50km bounding box.
      if (lat != null && lng != null) {
        const delta = 0.5;
        params['viewbox'] =
        '${lng - delta},${lat + delta},${lng + delta},${lat - delta}';
        params['bounded'] = 0;
      }

      final res = await _dio.get(_searchUrl, queryParameters: params);
      final results = res.data as List? ?? [];

      return results.map((r) {
        final map = r as Map<String, dynamic>;
        final placeId = map['place_id']?.toString() ?? '';
        final displayName = map['display_name'] as String? ?? '';
        final latVal = double.tryParse(map['lat']?.toString() ?? '');
        final lngVal = double.tryParse(map['lon']?.toString() ?? '');

        // Nominatim doesn't split main/secondary text like Google does —
        // approximate it by splitting the display name on the first comma.
        final parts = displayName.split(',');
        final mainText = parts.isNotEmpty ? parts.first.trim() : displayName;
        final secondaryText =
        parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        // Cache the full detail now so getPlaceDetail() below doesn't need
        // a second network call.
        if (placeId.isNotEmpty && latVal != null && lngVal != null) {
          _detailCache[placeId] = GeocodedPlace(
            latitude: latVal,
            longitude: lngVal,
            formattedAddress: displayName,
            placeId: placeId,
          );
        }

        return PlaceSuggestion(
          placeId: placeId,
          description: displayName,
          mainText: mainText,
          secondaryText: secondaryText,
          lat: latVal,
          lng: lngVal,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 4. Place Detail: placeId → lat/lng ───────────────────────────────────
  // Nominatim's search results already contain everything we need, so this
  // reads from the cache populated by getSuggestions() instead of making
  // another network call.

  Future<GeocodedPlace?> getPlaceDetail(String placeId, {double? lat, double? lng}) async {
    if (_detailCache.containsKey(placeId)) {
      return _detailCache[placeId];
    }
    if (lat != null && lng != null) {
      return GeocodedPlace(latitude: lat, longitude: lng, formattedAddress: '');
    }
    return null;
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