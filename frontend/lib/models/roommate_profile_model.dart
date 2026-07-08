import 'package:flutter/material.dart';
import 'onboarding_profile_model.dart' show kAvailableInterests; // reuse existing interest list

/// All enums mirror `backend/apps/roommate/models.py` TextChoices EXACTLY.
/// Do not rename values — `apiValue` must match the Django `choices` keys
/// or RoommateProfileSerializer will reject the payload with a 400.

enum SleepSchedule { earlyBird, nightOwl, flexible }

extension SleepScheduleApi on SleepSchedule {
  String get apiValue => switch (this) {
    SleepSchedule.earlyBird => 'early_bird',
    SleepSchedule.nightOwl => 'night_owl',
    SleepSchedule.flexible => 'flexible',
  };
  String get label => switch (this) {
    SleepSchedule.earlyBird => 'Early Bird',
    SleepSchedule.nightOwl => 'Night Owl',
    SleepSchedule.flexible => 'Flexible',
  };

  static SleepSchedule fromApiValue(String value) => SleepSchedule.values
      .firstWhere((e) => e.apiValue == value, orElse: () => SleepSchedule.flexible);
}

enum SmokingPreference { nonSmoker, smoker, occasional }

extension SmokingApi on SmokingPreference {
  String get apiValue => switch (this) {
    SmokingPreference.nonSmoker => 'non_smoker',
    SmokingPreference.smoker => 'smoker',
    SmokingPreference.occasional => 'occasional',
  };
  String get label => switch (this) {
    SmokingPreference.nonSmoker => 'Non-Smoker',
    SmokingPreference.smoker => 'Smoker',
    SmokingPreference.occasional => 'Occasional',
  };

  static SmokingPreference fromApiValue(String value) => SmokingPreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => SmokingPreference.nonSmoker);
}

enum DrinkingPreference { nonDrinker, drinker, social }

extension DrinkingApi on DrinkingPreference {
  String get apiValue => switch (this) {
    DrinkingPreference.nonDrinker => 'non_drinker',
    DrinkingPreference.drinker => 'drinker',
    DrinkingPreference.social => 'social',
  };
  String get label => switch (this) {
    DrinkingPreference.nonDrinker => 'Non-Drinker',
    DrinkingPreference.drinker => 'Drinker',
    DrinkingPreference.social => 'Social Drinker',
  };

  static DrinkingPreference fromApiValue(String value) => DrinkingPreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => DrinkingPreference.nonDrinker);
}

enum GuestsPreference { rarely, sometimes, frequently }

extension GuestsApi on GuestsPreference {
  String get apiValue => switch (this) {
    GuestsPreference.rarely => 'rarely',
    GuestsPreference.sometimes => 'sometimes',
    GuestsPreference.frequently => 'frequently',
  };
  String get label => switch (this) {
    GuestsPreference.rarely => 'Rarely',
    GuestsPreference.sometimes => 'Sometimes',
    GuestsPreference.frequently => 'Frequently',
  };

  static GuestsPreference fromApiValue(String value) => GuestsPreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => GuestsPreference.sometimes);
}

enum FoodPreference { vegetarian, nonVegetarian, vegan, noPreference }

extension FoodApi on FoodPreference {
  String get apiValue => switch (this) {
    FoodPreference.vegetarian => 'vegetarian',
    FoodPreference.nonVegetarian => 'non_vegetarian',
    FoodPreference.vegan => 'vegan',
    FoodPreference.noPreference => 'no_preference',
  };
  String get label => switch (this) {
    FoodPreference.vegetarian => 'Vegetarian',
    FoodPreference.nonVegetarian => 'Non-Vegetarian',
    FoodPreference.vegan => 'Vegan',
    FoodPreference.noPreference => 'No Preference',
  };

  static FoodPreference fromApiValue(String value) => FoodPreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => FoodPreference.noPreference);
}

enum PetsPreference { hasPets, noPets, okayWithPets, notOkayWithPets }

extension PetsApi on PetsPreference {
  String get apiValue => switch (this) {
    PetsPreference.hasPets => 'has_pets',
    PetsPreference.noPets => 'no_pets',
    PetsPreference.okayWithPets => 'okay_with_pets',
    PetsPreference.notOkayWithPets => 'not_okay_with_pets',
  };
  String get label => switch (this) {
    PetsPreference.hasPets => 'I Have Pets',
    PetsPreference.noPets => 'No Pets',
    PetsPreference.okayWithPets => 'Okay With Pets',
    PetsPreference.notOkayWithPets => 'Not Okay With Pets',
  };

  static PetsPreference fromApiValue(String value) => PetsPreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => PetsPreference.noPets);
}

enum StudyHabit { quiet, backgroundNoiseOk, groupStudy, rarelyStudiesAtHome }

extension StudyHabitApi on StudyHabit {
  String get apiValue => switch (this) {
    StudyHabit.quiet => 'quiet',
    StudyHabit.backgroundNoiseOk => 'background_noise_ok',
    StudyHabit.groupStudy => 'group_study',
    StudyHabit.rarelyStudiesAtHome => 'rarely_studies_at_home',
  };
  String get label => switch (this) {
    StudyHabit.quiet => 'Needs Quiet',
    StudyHabit.backgroundNoiseOk => 'Background Noise Okay',
    StudyHabit.groupStudy => 'Group Study',
    StudyHabit.rarelyStudiesAtHome => 'Rarely Studies At Home',
  };

  static StudyHabit fromApiValue(String value) => StudyHabit.values
      .firstWhere((e) => e.apiValue == value, orElse: () => StudyHabit.quiet);
}

enum RoommateGenderPreference { male, female, nonBinary, any }

extension RoommateGenderApi on RoommateGenderPreference {
  String get apiValue => switch (this) {
    RoommateGenderPreference.male => 'male',
    RoommateGenderPreference.female => 'female',
    RoommateGenderPreference.nonBinary => 'non_binary',
    RoommateGenderPreference.any => 'any',
  };
  String get label => switch (this) {
    RoommateGenderPreference.male => 'Male',
    RoommateGenderPreference.female => 'Female',
    RoommateGenderPreference.nonBinary => 'Non-Binary',
    RoommateGenderPreference.any => 'Any',
  };

  static RoommateGenderPreference fromApiValue(String value) => RoommateGenderPreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => RoommateGenderPreference.any);
}

enum RoomTypePreference { privateRoom, sharedRoom, entirePlace, any }

extension RoomTypeApi on RoomTypePreference {
  String get apiValue => switch (this) {
    RoomTypePreference.privateRoom => 'private_room',
    RoomTypePreference.sharedRoom => 'shared_room',
    RoomTypePreference.entirePlace => 'entire_place',
    RoomTypePreference.any => 'any',
  };
  String get label => switch (this) {
    RoomTypePreference.privateRoom => 'Private Room',
    RoomTypePreference.sharedRoom => 'Shared Room',
    RoomTypePreference.entirePlace => 'Entire Place',
    RoomTypePreference.any => 'Any',
  };

  static RoomTypePreference fromApiValue(String value) => RoomTypePreference.values
      .firstWhere((e) => e.apiValue == value, orElse: () => RoomTypePreference.any);
}

/// Same interest pool already used in Profile Setup — the backend
/// `RoommateProfile.interests` points at the same `apps.users.Interest`
/// model (see models.py comment), so there is no separate list to sync.
const List<String> kRoommateInterestOptions = kAvailableInterests;

/// Local state for the roommate compatibility quiz. Mirrors
/// `RoommateProfileSerializer` field-for-field so `toApiJson()` can be
/// POSTed to `/api/roommate/profile/` as-is once that call is wired up.
class RoommateQuizModel {
  int budgetMin;
  int budgetMax;

  SleepSchedule? sleepSchedule;
  TimeOfDay? wakeTime;

  SmokingPreference? smoking;
  DrinkingPreference? drinking;

  int cleanliness; // 1–5
  int noiseLevel; // 1–5

  GuestsPreference? guestsPreference;
  FoodPreference? foodPreference;
  PetsPreference? pets;
  StudyHabit? studyHabit;

  Set<String> interests;

  RoommateGenderPreference genderPreference;
  RoomTypePreference roomTypePreference;

  RoommateQuizModel({
    this.budgetMin = 8000,
    this.budgetMax = 15000,
    this.sleepSchedule,
    this.wakeTime,
    this.smoking,
    this.drinking,
    this.cleanliness = 3,
    this.noiseLevel = 3,
    this.guestsPreference,
    this.foodPreference,
    this.pets,
    this.studyHabit,
    Set<String>? interests,
    this.genderPreference = RoommateGenderPreference.any,
    this.roomTypePreference = RoomTypePreference.any,
  }) : interests = interests ?? {};

  /// Matches `RoommateProfileSerializer` fields exactly.
  /// NOTE: `interests` here is a list of names — swap for interest IDs
  /// once `/api/roommate/profile/` is actually called (the serializer
  /// expects `PrimaryKeyRelatedField` ids, not names).
  Map<String, dynamic> toApiJson() {
    final time = wakeTime;
    return {
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'sleep_schedule': sleepSchedule?.apiValue,
      'wake_time': time == null
          ? null
          : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
      'smoking': smoking?.apiValue,
      'drinking': drinking?.apiValue,
      'cleanliness': cleanliness,
      'noise_level': noiseLevel,
      'guests_preference': guestsPreference?.apiValue,
      'food_preference': foodPreference?.apiValue,
      'pets': pets?.apiValue,
      'study_habit': studyHabit?.apiValue,
      'interests': interests.toList(),
      'gender_preference': genderPreference.apiValue,
      'room_type_preference': roomTypePreference.apiValue,
    };
  }
}