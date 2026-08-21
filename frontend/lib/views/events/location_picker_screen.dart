import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../services/geocoding_service.dart';

/// Result returned when the user confirms a location.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String label; // Human-readable address from Geocoding API

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

/// Full-screen map location picker with:
///   • Address search bar with autocomplete dropdown
///   • GPS button to jump to current location
///   • Long-press / drag pin to set exact location
///   • Reverse geocoding: pin position → address label auto-fills
///   • Confirm button returns [PickedLocation] to caller
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  static const _defaultKathmandu = LatLng(27.7172, 85.3240);

  late LatLng _pinPosition;
  String _addressLabel = '';
  bool _loadingGps = false;
  bool _loadingAddress = false;

  // Best-effort "my location" dot on the map. Fetched once (not on every
  // build like a FutureBuilder would) since it's just a visual reference,
  // not something that needs to live-update while picking a location.
  Position? _myPosition;

  // Autocomplete
  List<PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pinPosition = widget.initial ?? _defaultKathmandu;
    // Reverse geocode the initial position
    _reverseGeocode(_pinPosition.latitude, _pinPosition.longitude);
    _loadMyPosition();
  }

  Future<void> _loadMyPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return; // don't prompt just for the dot — GPS button handles prompting
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {
      // Silent — the dot just won't show, no functional impact.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Reverse geocode: pin → address ────────────────────────────────────────

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _loadingAddress = true);
    final address = await GeocodingService.instance.reverseGeocode(lat, lng);
    if (mounted) {
      setState(() {
        _addressLabel = address ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
        _loadingAddress = false;
      });
    }
  }

  // ── Pin moved ─────────────────────────────────────────────────────────────

  void _onPinMoved(LatLng newPos) {
    setState(() => _pinPosition = newPos);
    _reverseGeocode(newPos.latitude, newPos.longitude);
  }

  // ── Autocomplete: typing → suggestions ───────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final suggestions = await GeocodingService.instance.getSuggestions(
        value,
        lat: _pinPosition.latitude,
        lng: _pinPosition.longitude,
      );
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
        });
      }
    });
  }

  // ── Suggestion tapped: placeId → lat/lng ─────────────────────────────────

  Future<void> _onSuggestionTapped(PlaceSuggestion suggestion) async {
    _focusNode.unfocus();
    setState(() { _showSuggestions = false; _loadingAddress = true; });
    _searchController.text = suggestion.mainText;

    final place = await GeocodingService.instance.getPlaceDetail(
      suggestion.placeId,
      lat: suggestion.lat,
      lng: suggestion.lng,
    );
    if (place != null && mounted) {
      final newPos = LatLng(place.latitude, place.longitude);
      setState(() {
        _pinPosition = newPos;
        _addressLabel = place.formattedAddress;
        _loadingAddress = false;
      });
      _mapController.move(newPos, 16);
    } else {
      setState(() => _loadingAddress = false);
    }
  }

  // ── GPS button ────────────────────────────────────────────────────────────

  Future<void> _jumpToMyLocation() async {
    setState(() => _loadingGps = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied. Enable in Settings.')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final newPos = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        _onPinMoved(newPos);
        _mapController.move(newPos, 16);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location.')),
      );
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────

  void _confirm() {
    context.pop(PickedLocation(
      latitude: _pinPosition.latitude,
      longitude: _pinPosition.longitude,
      label: _addressLabel.isNotEmpty
          ? _addressLabel
          : '${_pinPosition.latitude.toStringAsFixed(5)}, '
          '${_pinPosition.longitude.toStringAsFixed(5)}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [

          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pinPosition,
              initialZoom: 15,
              onLongPress: (_, pos) {
                _onPinMoved(pos);
                _mapController.move(pos, _mapController.camera.zoom);
              },
              // Dismiss suggestions when tapping the map
              onTap: (_, __) {
                _focusNode.unfocus();
                setState(() => _showSuggestions = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tribal.app',
              ),
              // My-location marker (blue dot)
              if (_myPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_myPosition!.latitude, _myPosition!.longitude),
                    width: 18, height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ),
                ]),
              // Draggable destination pin
              DragMarkers(
                markers: [
                  DragMarker(
                    point: _pinPosition,
                    size: const Size(40, 40),
                    offset: const Offset(0, -20),
                    dragOffset: const Offset(0, -20),
                    builder: (ctx, pos, isDragging) => Icon(
                      Icons.location_pin,
                      color: AppColors.primary,
                      size: isDragging ? 46 : 40,
                    ),
                    onDragEnd: (details, newPos) => _onPinMoved(newPos),
                  ),
                ],
              ),
            ],
          ),

          // ── Top bar: back + search ────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16, right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Search field
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search for a place...',
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() { _suggestions = []; _showSuggestions = false; });
                              },
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Autocomplete dropdown ─────────────────────────────────
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 50),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _suggestions.length.clamp(0, 5),
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 18),
                          title: Text(s.mainText,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          subtitle: s.secondaryText.isNotEmpty
                              ? Text(s.secondaryText,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textSecondary))
                              : null,
                          onTap: () => _onSuggestionTapped(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── GPS button ────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: botPad + 130,
            child: GestureDetector(
              onTap: _loadingGps ? null : _jumpToMyLocation,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: _loadingGps
                    ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 22),
              ),
            ),
          ),

          // ── Address display ───────────────────────────────────────────────
          Positioned(
            left: 16, right: 16,
            bottom: botPad + 82,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _loadingAddress
                        ? Row(children: [
                      const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text('Getting address...',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ])
                        : Text(
                      _addressLabel.isNotEmpty
                          ? _addressLabel
                          : 'Long-press map or drag pin to set location',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _addressLabel.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textHint),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Confirm button ────────────────────────────────────────────────
          Positioned(
            left: 20, right: 20,
            bottom: botPad + 24,
            child: ElevatedButton(
              onPressed: _loadingAddress ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
              ),
              child: Text(
                'Confirm Location',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}