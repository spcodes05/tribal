import '../core/network/api_client.dart';
import '../models/roommate_match_model.dart';
import '../services/roommate_service.dart';
import 'package:flutter/material.dart';
import '../models/roommate_profile_model.dart';

/// Drives the 14-step roommate compatibility quiz
/// (RoommateIntroScreen → ... → ReviewScreen → FindingRoommateScreen).
///
/// One instance is provided at the top of the `/roommate/*` ShellRoute so
/// data survives across every step, same pattern as [ProfileSetupController].
/// No backend calls yet — [submitQuiz] only validates + stubs a delay.
class RoommateQuizController extends ChangeNotifier {
  final RoommateQuizModel profile = RoommateQuizModel();

  static const int totalSteps = 14;

  // ── Budget ───────────────────────────────────────────────────────────────
  void setBudget(int min, int max) {
    profile.budgetMin = min;
    profile.budgetMax = max;
    notifyListeners();
  }

  bool get isBudgetValid => profile.budgetMax >= profile.budgetMin;

  // ── Sleep schedule ───────────────────────────────────────────────────────
  void setSleepSchedule(SleepSchedule value) {
    profile.sleepSchedule = value;
    notifyListeners();
  }

  void setWakeTime(TimeOfDay value) {
    profile.wakeTime = value;
    notifyListeners();
  }

  bool get isSleepScheduleValid =>
      profile.sleepSchedule != null && profile.wakeTime != null;

  // ── Smoking / Drinking ───────────────────────────────────────────────────
  void setSmoking(SmokingPreference value) {
    profile.smoking = value;
    notifyListeners();
  }

  void setDrinking(DrinkingPreference value) {
    profile.drinking = value;
    notifyListeners();
  }

  // ── Cleanliness / Noise (1–5 scale, per scoring.py) ─────────────────────
  void setCleanliness(int value) {
    profile.cleanliness = value.clamp(1, 5);
    notifyListeners();
  }

  void setNoiseLevel(int value) {
    profile.noiseLevel = value.clamp(1, 5);
    notifyListeners();
  }

  // ── Guests / Food / Pets / Study habit ──────────────────────────────────
  void setGuestsPreference(GuestsPreference value) {
    profile.guestsPreference = value;
    notifyListeners();
  }

  void setFoodPreference(FoodPreference value) {
    profile.foodPreference = value;
    notifyListeners();
  }

  void setPets(PetsPreference value) {
    profile.pets = value;
    notifyListeners();
  }

  void setStudyHabit(StudyHabit value) {
    profile.studyHabit = value;
    notifyListeners();
  }

  // ── Interests ────────────────────────────────────────────────────────────
  void toggleInterest(String interest) {
    if (profile.interests.contains(interest)) {
      profile.interests.remove(interest);
    } else {
      profile.interests.add(interest);
    }
    notifyListeners();
  }

  bool isInterestSelected(String interest) =>
      profile.interests.contains(interest);

  // ── Gender / Room type preference ───────────────────────────────────────
  void setGenderPreference(RoommateGenderPreference value) {
    profile.genderPreference = value;
    notifyListeners();
  }

  void setRoomTypePreference(RoomTypePreference value) {
    profile.roomTypePreference = value;
    notifyListeners();
  }

  // ── Submission (mirrors ProfileSetupController.submitProfile exactly) ──
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String? _submitError;

  String? get submitError => _submitError;

  bool get isQuizComplete =>
      isBudgetValid &&
          isSleepScheduleValid &&
          profile.smoking != null &&
          profile.drinking != null &&
          profile.guestsPreference != null &&
          profile.foodPreference != null &&
          profile.pets != null &&
          profile.studyHabit != null;

  /// POSTs `profile.toApiJson()` to `/api/roommate/profile/` via
  /// [RoommateService]. Returns false without navigating on any failure —
  /// caller (FindingRoommateScreen) is responsible for staying put and
  /// showing [submitError].
  Future<bool> submitQuiz() async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await RoommateService.instance.submitProfile(profile.toApiJson());
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmitting = false;
      _submitError = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isSubmitting = false;
      _submitError = 'Something went wrong while saving your roommate profile.';
      notifyListeners();
      return false;
    }
  }

  // ── Matches ──────────────────────────────────────────────────────────────
  bool _isLoadingMatches = false;

  bool get isLoadingMatches => _isLoadingMatches;

  String? _matchesError;

  String? get matchesError => _matchesError;

  List<RoommateMatchResult> _matches = [];

  List<RoommateMatchResult> get matches => _matches;

  /// GETs `/api/roommate/find/`. Called by FindingRoommateScreen right
  /// after a successful [submitQuiz], and again by RoommateHomeScreen on
  /// first load if it's opened directly (e.g. bottom-nav tap) with no
  /// matches cached yet in this session.
  Future<void> fetchMatches() async {
    _isLoadingMatches = true;
    _matchesError = null;
    notifyListeners();

    try {
      _matches = await RoommateService.instance.fetchMatches();
    } on ApiException catch (e) {
      _matchesError = e.message;
      _matches = [];
    } catch (_) {
      _matchesError = 'Could not load your matches. Please try again.';
      _matches = [];
    } finally {
      _isLoadingMatches = false;
      notifyListeners();
    }
  }
}

