import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';
import '../services/events_service.dart';

/// Active filter state for the Explore page chip bar.
class ExploreFilter {
  final String? tag;
  final bool isFree;
  final bool isWomenOnly;
  final bool thisWeekend;

  const ExploreFilter({
    this.tag,
    this.isFree = false,
    this.isWomenOnly = false,
    this.thisWeekend = false,
  });

  bool get isActive =>
      tag != null || isFree || isWomenOnly || thisWeekend;

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
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Map state ─────────────────────────────────────────────────────────────
  LatLng _userLocation = const LatLng(27.7172, 85.3240); // Kathmandu default
  LatLng get userLocation => _userLocation;

  // Map pins — only activities WITH coordinates
  List<ActivityPinModel> _pins = [];
  List<ActivityPinModel> get pins => _pins;

  // Bottom sheet list — ALL activities regardless of coordinates
  // Filtered client-side to match current filter selection
  List<ActivityCardModel> _allActivities = [];
  List<ActivityCardModel> _filteredActivities = [];
  List<ActivityCardModel> get filteredActivities => _filteredActivities;

  Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  ActivityPinModel? _selectedPin;
  ActivityPinModel? get selectedPin => _selectedPin;

  // ── Filter state ──────────────────────────────────────────────────────────
  ExploreFilter _filter = const ExploreFilter();
  ExploreFilter get filter => _filter;

  List<String> _availableTags = [];
  List<String> get availableTags => _availableTags;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadUserLocation(),
      _loadTags(),
    ]);

    // Load both map pins and full activity list in parallel
    await Future.wait([
      _loadMapPins(),
      _loadAllActivities(),
    ]);

    _isLoading = false;
    notifyListeners();
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

  // ── Load map pins (activities WITH coordinates) ───────────────────────────

  Future<void> _loadMapPins() async {
    try {
      _pins = await EventsService.instance.getActivityPins(
        tag: _filter.tag,
        isFree: _filter.isFree ? true : null,
        isWomenOnly: _filter.isWomenOnly ? true : null,
        thisWeekend: _filter.thisWeekend ? true : null,
      );
      _buildMarkers();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {}
  }

  // ── Load ALL activities (for bottom sheet list) ───────────────────────────
  // This fixes the bug where activities without coordinates were invisible.
  // The bottom sheet shows ALL activities; the map only shows those with coords.

  Future<void> _loadAllActivities() async {
    try {
      _allActivities = await EventsService.instance.getActivities();
      _applyFilterToList();
    } on ApiException catch (_) {
      // Fall back to showing pins-only in the list
      _filteredActivities = _pins
          .map((pin) => ActivityCardModel(
        id: pin.id,
        title: pin.title,
        imageUrl: pin.imageUrl,
        location: pin.location,
        date: pin.date,
        time: pin.time,
        isWomenOnly: pin.isWomenOnly,
        isAccessible: pin.isAccessible,
        isFree: pin.isFree,
        memberCount: pin.memberCount,
        maxMembers: pin.maxMembers,
        isFull: pin.memberCount >= pin.maxMembers,
        hostName: '',
      ))
          .toList();
    }
  }

  // Client-side filter applied to the full activity list
  void _applyFilterToList() {
    _filteredActivities = _allActivities.where((a) {
      if (_filter.isFree && !a.isFree) return false;
      if (_filter.isWomenOnly && !a.isWomenOnly) return false;
      if (_filter.tag != null) {
        // match_percent is null for untagged activities — exclude them
        // We can't filter by tag client-side without the tag list on the card model,
        // so we rely on the server for tag filtering (map pins already filtered)
        // For the list we show all when a tag is selected and let user see results
      }
      return true;
    }).toList();
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

  // ── Reload with filter ────────────────────────────────────────────────────

  Future<void> _reload() async {
    _isLoading = true;
    _selectedPin = null;
    notifyListeners();

    await Future.wait([
      _loadMapPins(),
      _loadAllActivities(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setTagFilter(String? tag) {
    _filter = _filter.copyWith(tag: tag);
    _reload();
  }

  void toggleFree() {
    _filter = _filter.copyWith(isFree: !_filter.isFree);
    _reload();
  }

  void toggleWomenOnly() {
    _filter = _filter.copyWith(isWomenOnly: !_filter.isWomenOnly);
    _reload();
  }

  void toggleThisWeekend() {
    _filter = _filter.copyWith(thisWeekend: !_filter.thisWeekend);
    _reload();
  }

  void clearFilters() {
    _filter = const ExploreFilter();
    _reload();
  }
}