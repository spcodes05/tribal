import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/activity_model.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

enum ProfileStatus { idle, loading, success, error }

/// Backs "Your Tribe Status" and "Other User Profile" — same
/// status/isLoading/error convention as [HomeController].
class ProfileController extends ChangeNotifier {
  ProfileStatus _status = ProfileStatus.idle;
  ProfileStatus get status => _status;
  bool get isLoading => _status == ProfileStatus.loading;

  String? _error;
  String? get error => _error;

  // ── Tribe Status (own profile) ───────────────────────────────────────────
  TribeStatusModel? _tribeStatus;
  TribeStatusModel? get tribeStatus => _tribeStatus;

  ActivityCardModel? get upcomingActivity {
    final raw = _tribeStatus?.upcomingActivityJson;
    if (raw == null) return null;
    return ActivityCardModel.fromJson(raw as Map<String, dynamic>);
  }

  Future<void> loadTribeStatus() async {
    _status = ProfileStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _tribeStatus = await ProfileService.instance.getTribeStatus();
      _status = ProfileStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status = ProfileStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // ── Other User Profile ───────────────────────────────────────────────────
  PublicProfileModel? _otherProfile;
  PublicProfileModel? get otherProfile => _otherProfile;

  Future<void> loadOtherProfile(int userId) async {
    _status = ProfileStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _otherProfile = await ProfileService.instance.getPublicProfile(userId);
      _status = ProfileStatus.success;
    } on ApiException catch (e) {
      _error = e.message;
      _status = ProfileStatus.error;
    } finally {
      notifyListeners();
    }
  }

  bool _isBlockActionRunning = false;
  bool get isBlockActionRunning => _isBlockActionRunning;

  Future<bool> toggleBlock(int userId) async {
    if (_otherProfile == null) return false;
    _isBlockActionRunning = true;
    notifyListeners();
    try {
      if (_otherProfile!.isBlockedByMe) {
        await ProfileService.instance.unblockUser(userId);
      } else {
        await ProfileService.instance.blockUser(userId);
      }
      final wasBlocked = _otherProfile!.isBlockedByMe;
      _otherProfile = PublicProfileModel(
        core: _otherProfile!.core,
        mutualInterests: _otherProfile!.mutualInterests,
        compatibilityPercent: _otherProfile!.compatibilityPercent,
        activitiesJoined: _otherProfile!.activitiesJoined,
        recentPublicEvents: _otherProfile!.recentPublicEvents,
        isBlockedByMe: !wasBlocked,
      );
      _isBlockActionRunning = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isBlockActionRunning = false;
      notifyListeners();
      return false;
    }
  }

  bool _isSubmittingReport = false;
  bool get isSubmittingReport => _isSubmittingReport;

  Future<bool> reportUser(int userId, {required String reason, String details = ''}) async {
    _isSubmittingReport = true;
    notifyListeners();
    try {
      await ProfileService.instance.reportUser(userId, reason: reason, details: details);
      _isSubmittingReport = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isSubmittingReport = false;
      notifyListeners();
      return false;
    }
  }

  // ── Profile Settings ─────────────────────────────────────────────────────
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await ProfileService.instance.updateProfile(data);
      _isSaving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}