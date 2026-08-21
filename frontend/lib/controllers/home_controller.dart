import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';
import '../services/events_service.dart';

enum HomeStatus { idle, loading, success, error }

/// Controller for the Home screen and all its sub-screens
/// (notifications, search, see-all, create activity).
class HomeController extends ChangeNotifier {
  HomeStatus _status = HomeStatus.idle;
  HomeStatus get status => _status;

  String? _error;
  String? get error => _error;

  bool get isLoading => _status == HomeStatus.loading;

  // ── Home feed ─────────────────────────────────────────────────────────────
  List<ActivityCardModel> _activities = [];
  List<ActivityCardModel> get activities => _activities;

  List<PersonMatchModel> _people = [];
  List<PersonMatchModel> get people => _people;

  int _unreadNotifications = 0;
  int get unreadNotifications => _unreadNotifications;

  Future<void> loadHomeFeed() async {
    _status = HomeStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final data = await EventsService.instance.getHomeFeed();
      _activities = data['activities'] as List<ActivityCardModel>;
      _people = data['people'] as List<PersonMatchModel>;
      _unreadNotifications = data['unread_notifications'] as int;
      _status = HomeStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status = HomeStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // ── Activity detail ────────────────────────────────────────────────────────
  ActivityDetailModel? _activityDetail;
  ActivityDetailModel? get activityDetail => _activityDetail;
  bool _isJoining = false;
  bool get isJoining => _isJoining;

  Future<void> loadActivityDetail(int id) async {
    _status = HomeStatus.loading;
    _activityDetail = null;
    notifyListeners();

    try {
      _activityDetail = await EventsService.instance.getActivityDetail(id);
      _status = HomeStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status = HomeStatus.error;
    } catch (e) {
      // Catch-all so any unexpected error (e.g. a parsing bug) surfaces as
      // a retryable error state instead of leaving isLoading stuck forever.
      _error = 'Something went wrong loading this activity.';
      _status = HomeStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> toggleJoin(int activityId) async {
    if (_activityDetail == null) return false;
    _isJoining = true;
    notifyListeners();

    try {
      if (_activityDetail!.hasJoined) {
        final res = await EventsService.instance.leaveActivity(activityId);
        _activityDetail = _activityDetail!.copyWith(
          hasJoined: false,
          memberCount: res['member_count'] as int? ?? _activityDetail!.memberCount - 1,
        );
      } else {
        final res = await EventsService.instance.joinActivity(activityId);
        _activityDetail = _activityDetail!.copyWith(
          hasJoined: true,
          memberCount: res['member_count'] as int? ?? _activityDetail!.memberCount + 1,
        );
      }
      _isJoining = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isJoining = false;
      notifyListeners();
      return false;
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  Future<void> loadNotifications() async {
    try {
      _notifications = await EventsService.instance.getNotifications();
      _unreadNotifications = 0; // mark all read after opening
      notifyListeners();
      await EventsService.instance.markAllNotificationsRead();
    } on ApiException catch (_) {}
  }

  // ── Create Activity ────────────────────────────────────────────────────────
  bool _isCreating = false;
  bool get isCreating => _isCreating;

  Future<ActivityDetailModel?> createActivity(Map<String, dynamic> data) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final created = await EventsService.instance.createActivity(data);
      _isCreating = false;
      // Refresh the feed so new activity appears
      loadHomeFeed();
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _error = e.message;
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  List<ActivityCardModel> _searchActivities = [];
  List<ActivityCardModel> get searchActivities => _searchActivities;

  List<PersonMatchModel> _searchPeople = [];
  List<PersonMatchModel> get searchPeople => _searchPeople;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchActivities = [];
      _searchPeople = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();

    try {
      final data = await EventsService.instance.search(query);
      _searchActivities = data['activities'] as List<ActivityCardModel>;
      _searchPeople = data['people'] as List<PersonMatchModel>;
    } on ApiException catch (_) {}

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchActivities = [];
    _searchPeople = [];
    notifyListeners();
  }
}