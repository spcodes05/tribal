import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';

/// Submits onboarding data (gender, interests) to the Django backend.
///
/// Both endpoints require:
///   - a valid JWT access token (attached automatically by [ApiClient])
///   - the user's email to already be verified, otherwise the backend
///     returns 403 with detail "Please verify your email first."
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  Dio get _dio => ApiClient.instance.dio;

  /// POST /api/users/gender/
  /// [genderApiValue] must be one of: male, female, non_binary, prefer_not_to_say
  /// (see GenderApiValue extension in onboarding_profile_model.dart).
  Future<void> submitGender(String genderApiValue) async {
    try {
      await _dio.post(ApiConfig.gender, data: {'gender': genderApiValue});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/users/interests/
  /// [interestNames] must exactly match names in the backend's
  /// PREDEFINED_INTERESTS list — see kAvailableInterests for the synced copy.
  ///
  /// Note: this REPLACES the user's full interest list (not additive).
  Future<void> submitInterests(List<String> interestNames) async {
    try {
      await _dio.post(ApiConfig.interests, data: {'interests': interestNames});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/users/interests/
  /// Returns the predefined interest list from the backend directly,
  /// useful as a source of truth instead of the hardcoded frontend copy.
  Future<List<String>> fetchAvailableInterests() async {
    try {
      final response = await _dio.get(ApiConfig.interests);
      final data = response.data as Map<String, dynamic>;
      final list = data['interests'] as List<dynamic>;
      return list.map((e) => (e as Map)['name'].toString()).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
