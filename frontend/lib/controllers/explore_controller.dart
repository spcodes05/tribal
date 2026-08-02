import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';
import '../services/events_service.dart';

enum ExploreStatus { idle, loading, success, error }

/// Active filter state for the Explore page chip bar.
class ExploreFilter {
  final String? tag;      // Interest tag name e.g. "Hiking", or null for All
  final bool isFree;
  final bool isWomenOnly;
  final bool thisWeekend;

  const ExploreFilter({
    this.tag,
    this.isFree = false,
    this.isWomenOnly = false,
    this.thisWeekend = false,
  });

  ExploreFilter copyWith({
    Object? tag = _sentinel,
    bool? isFree,
    bool? isWomenOnly,
    bool? thisWeekend,
  }) {
    return ExploreFilter(
      tag: tag == _sentinel ? this.tag : tag as String?,
      isFree: isFree ?? this.isFree,
      isWomenOnly: isWomenOnly ?? this.isWomenOnly,
      thisWeekend: thisWeekend ?? this.thisWeekend,
    );
  }

  static const _sentinel = Object();
}

class ExploreController extends ChangeNotifier {
  ExploreStatus _status = ExploreStatus.idle;
  ExploreStatus get status => _status;

  String? _error;
  String? get error => _error;
  bool get isLoading => _status == ExploreStatus.loading;

  // ── Map state ─────────────────────────────────────────────────────────────
  LatLng _userLocation = const LatLng(27.7172, 85.3240); // Kathmandu default
  LatLng get userLocation => _userLocation;

  List<ActivityPinModel> _pins = [];
  List<ActivityPinModel> get pins => _pins;

  Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  // Currently tapped pin (shows bottom sheet detail)
  ActivityPinModel? _selectedPin;
  ActivityPinModel? get selectedPin => _selectedPin;

  // ── Filter state ──────────────────────────────────────────────────────────
  ExploreFilter _filter = const ExploreFilter();
  ExploreFilter get filter => _filter;

  List<String> _availableTags = [];
  List<String> get availableTags => _availableTags;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _status = ExploreStatus.loading;
    notifyListeners();

    await Future.wait([
      _loadUserLocation(),
      _loadTags(),
    ]);

    await loadPins();
  }

  Future<void> _loadUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _userLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Keep default Kathmandu coords
    }
  }

  Future<void> _loadTags() async {
    try {
      final interests = await EventsService.instance.fetchInterests();
      _availableTags = interests.map((e) => e['name'] as String).toList();
    } catch (_) {}
  }

  // ── Load pins with current filter ─────────────────────────────────────────

  Future<void> loadPins() async {
    _status = ExploreStatus.loading;
    notifyListeners();

    try {
      _pins = await EventsService.instance.getActivityPins(
        tag: _filter.tag,
        isFree: _filter.isFree ? true : null,
        isWomenOnly: _filter.isWomenOnly ? true : null,
        thisWeekend: _filter.thisWeekend ? true : null,
      );
      _buildMarkers();
      _status = ExploreStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status = ExploreStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void _buildMarkers() {
    _markers = _pins.map((pin) {
      return Marker(
        markerId: MarkerId('activity_${pin.id}'),
        position: LatLng(pin.latitude, pin.longitude),
        onTap: () => selectPin(pin),
        infoWindow: InfoWindow(title: pin.pinLabel),
      );
    }).toSet();
  }

  void selectPin(ActivityPinModel? pin) {
    _selectedPin = pin;
    notifyListeners();
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setTagFilter(String? tag) {
    _filter = _filter.copyWith(tag: tag);
    _selectedPin = null;
    loadPins();
  }

  void toggleFree() {
    _filter = _filter.copyWith(isFree: !_filter.isFree);
    _selectedPin = null;
    loadPins();
  }

  void toggleWomenOnly() {
    _filter = _filter.copyWith(isWomenOnly: !_filter.isWomenOnly);
    _selectedPin = null;
    loadPins();
  }

  void toggleThisWeekend() {
    _filter = _filter.copyWith(thisWeekend: !_filter.thisWeekend);
    _selectedPin = null;
    loadPins();
  }

  void clearFilters() {
    _filter = const ExploreFilter();
    _selectedPin = null;
    loadPins();
  }
}